#!/bin/bash
dnf update -y
dnf install -y python3-pip
pip3 install flask pymysql boto3

# 1. Create directory structure
mkdir -p /opt/rdsapp/static

# 2. Create static test files
echo "CloudFront Cache Test File" > /opt/rdsapp/static/test.txt

# Static index.html for invalidation testing (Lab 2B-Honors+)
cat > /opt/rdsapp/static/index.html <<'HTML'
<!DOCTYPE html>
<html>
<head><title>Static Entry Point</title></head>
<body>
<h1>Static Index - Version 1</h1>
<p>Deploy timestamp: initial build</p>
<p>To test invalidation: update this file on origin, then invalidate /static/index.html</p>
</body>
</html>
HTML

# 3. Create the Flask Application
cat >/opt/rdsapp/app.py <<'PY'
import json
import os
from datetime import datetime, timezone
import boto3
import pymysql
import logging
from flask import Flask, request, jsonify, send_from_directory, make_response

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__, static_folder=None)  # Disable default static folder to use custom handler
REGION = "us-east-1"
SECRET_ID = os.environ.get("SECRET_ID")
CF_PASSWORD = os.environ.get("CF_PW")
PARAM_ENDPOINT = "/lab/db/endpoint"
PARAM_DBNAME = "/lab/db/name"

ssm = boto3.client("ssm", region_name=REGION)
secrets = boto3.client("secretsmanager", region_name=REGION)

def get_config():
    # Fetch Non-Sensitive Info from Parameter Store
    try:
        logger.info(f"Fetching SSM parameter: {PARAM_ENDPOINT}")
        host = ssm.get_parameter(Name=PARAM_ENDPOINT)["Parameter"]["Value"]
        logger.info(f"Retrieved host: {host}")

        logger.info(f"Fetching SSM parameter: {PARAM_DBNAME}")
        dbname = ssm.get_parameter(Name=PARAM_DBNAME)["Parameter"]["Value"]
        logger.info(f"Retrieved dbname: {dbname}")

        return host, dbname
    except Exception as e:
        logger.error(f"Failed to fetch SSM Parameters: {str(e)} | Type: {type(e).__name__}")
        raise e

def get_db_creds():
    try:
        logger.info(f"Fetching secret from Secrets Manager: {SECRET_ID}")
        client = boto3.client("secretsmanager", region_name=REGION)
        resp = client.get_secret_value(SecretId=SECRET_ID)
        creds = json.loads(resp["SecretString"])
        logger.info(f"Successfully retrieved secret with keys: {list(creds.keys())}")
        return creds
    except Exception as e:
        logger.error(f"Failed to fetch Secrets: {str(e)} | Type: {type(e).__name__}")
        raise e

def get_conn():
    c = get_db_creds()
    # Handle the fact that AWS Secrets for RDS use different key names
    return pymysql.connect(
        host=c.get("host"), 
        user=c.get("username"), 
        password=c.get("password"),
        port=int(c.get("port", 3306)), 
        database=c.get("dbname", "labdb"),
        autocommit=True
    )

@app.route("/")
def home():
    return """
    <h2>Lab 2B: CloudFront + RDS</h2>
    <h3>Debug Endpoints:</h3>
    <ul>
        <li><a href='/health'>Health Check</a> - Verify app is running</li>
        <li><a href='/test-ssm'>Test SSM Parameters</a> - Check Parameter Store access</li>
        <li><a href='/test-secrets'>Test Secrets Manager</a> - Check Secrets access</li>
        <li><a href='/test-db'>Test DB Connection</a> - Check RDS connectivity</li>
        <li><a href='/debug'>Debug Headers</a> - CloudFront header verification</li>
        <li><a href='/static/test.txt'>Static File</a> - Test static content</li>
        <li><a href='/static/index.html'>Static Index</a> - Invalidation test target</li>
        <li><a href='/init'>Init DB</a> - Initialize database</li>
        <li><a href='/api/public-feed'>Public Feed</a> - Cacheable (s-maxage=30)</li>
        <li><a href='/api/list'>API List</a> - Private (no-store, never cached)</li>
    </ul>
    """

@app.route("/health")
def health():
    """Public GET endpoint with safe caching via origin Cache-Control"""
    response = make_response(jsonify({
        "status": "healthy",
        "message": "Flask application is running",
        "region": REGION,
        "secret_id_env": "set" if SECRET_ID else "NOT SET",
        "cf_password_env": "set" if CF_PASSWORD else "NOT SET"
    }))
    # Safe caching: origin explicitly opts in to 30s cache
    response.headers["Cache-Control"] = "public, max-age=30"
    return response

@app.route("/test-ssm")
def test_ssm():
    """Test SSM Parameter Store access"""
    try:
        logger.info(f"Testing SSM access for endpoint: {PARAM_ENDPOINT}")
        host = ssm.get_parameter(Name=PARAM_ENDPOINT)["Parameter"]["Value"]
        logger.info(f"Successfully retrieved endpoint: {host}")

        logger.info(f"Testing SSM access for dbname: {PARAM_DBNAME}")
        dbname = ssm.get_parameter(Name=PARAM_DBNAME)["Parameter"]["Value"]
        logger.info(f"Successfully retrieved dbname: {dbname}")

        return jsonify({
            "status": "success",
            "message": "SSM Parameter Store access working",
            "endpoint": host,
            "dbname": dbname,
            "param_paths": {
                "endpoint": PARAM_ENDPOINT,
                "dbname": PARAM_DBNAME
            }
        })
    except Exception as e:
        logger.error(f"SSM Parameter Store access failed: {str(e)}")
        return jsonify({
            "status": "error",
            "message": "Failed to access SSM Parameter Store",
            "error": str(e),
            "error_type": type(e).__name__,
            "param_paths": {
                "endpoint": PARAM_ENDPOINT,
                "dbname": PARAM_DBNAME
            }
        }), 500

@app.route("/test-secrets")
def test_secrets():
    """Test Secrets Manager access"""
    try:
        logger.info(f"Testing Secrets Manager access for secret: {SECRET_ID}")

        # Get raw secret first
        client = boto3.client("secretsmanager", region_name=REGION)
        resp = client.get_secret_value(SecretId=SECRET_ID)
        raw_secret = resp["SecretString"]

        logger.info(f"Raw secret length: {len(raw_secret)}")
        logger.info(f"Raw secret preview (first 200 chars): {raw_secret[:200]}")

        # Try to parse it
        creds = json.loads(raw_secret)
        logger.info(f"Successfully retrieved secret with keys: {list(creds.keys())}")

        return jsonify({
            "status": "success",
            "message": "Secrets Manager access working",
            "secret_id": SECRET_ID,
            "raw_secret_length": len(raw_secret),
            "raw_secret_preview": raw_secret[:200],
            "keys_present": list(creds.keys()),
            "username": creds.get("username", "NOT FOUND"),
            "has_password": "password" in creds,
            "host": creds.get("host", "NOT FOUND"),
            "port": creds.get("port", "NOT FOUND"),
            "dbname": creds.get("dbname", "NOT FOUND")
        })
    except json.JSONDecodeError as e:
        logger.error(f"JSON parsing failed: {str(e)}")
        return jsonify({
            "status": "error",
            "message": "Failed to parse secret JSON",
            "error": str(e),
            "error_type": "JSONDecodeError",
            "secret_id": SECRET_ID,
            "raw_secret": raw_secret if 'raw_secret' in locals() else "N/A",
            "parse_error_position": f"line {e.lineno} column {e.colno}"
        }), 500
    except Exception as e:
        logger.error(f"Secrets Manager access failed: {str(e)}")
        return jsonify({
            "status": "error",
            "message": "Failed to access Secrets Manager",
            "error": str(e),
            "error_type": type(e).__name__,
            "secret_id": SECRET_ID
        }), 500

@app.route("/test-db")
def test_db():
    """Test database connectivity"""
    try:
        logger.info("Testing database connection via get_conn()")
        conn = get_conn()
        logger.info("Database connection successful")

        cur = conn.cursor()
        cur.execute("SELECT VERSION();")
        version = cur.fetchone()
        cur.close()
        conn.close()

        return jsonify({
            "status": "success",
            "message": "Database connection working",
            "mysql_version": str(version)
        })
    except Exception as e:
        logger.error(f"Database connection failed: {str(e)}")
        return jsonify({
            "status": "error",
            "message": "Failed to connect to database",
            "error": str(e),
            "error_type": type(e).__name__
        }), 500

@app.route("/init")
def init_db():
    try:
        # Step 1: Get config from SSM
        logger.info("Step 1: Fetching SSM parameters...")
        host, dbname = get_config()
        logger.info(f"Step 1 SUCCESS: host={host}, dbname={dbname}")

        # Step 2: Get credentials from Secrets Manager
        logger.info("Step 2: Fetching credentials from Secrets Manager...")
        creds = get_db_creds()
        user = creds.get("username")
        password = creds.get("password")
        logger.info(f"Step 2 SUCCESS: user={user}, password={'***' if password else 'MISSING'}")

        # Step 3: Connect to MySQL
        logger.info(f"Step 3: Connecting to MySQL at {host}:3306...")
        conn = pymysql.connect(host=host, user=user, password=password, port=3306, autocommit=True)
        logger.info("Step 3 SUCCESS: MySQL connection established")

        # Step 4: Create database
        logger.info(f"Step 4: Creating database {dbname}...")
        cur = conn.cursor()
        cur.execute(f"CREATE DATABASE IF NOT EXISTS `{dbname}`;")
        logger.info(f"Step 4 SUCCESS: Database {dbname} created/exists")

        # Step 5: Use database and create table
        logger.info(f"Step 5: Creating notes table in {dbname}...")
        cur.execute(f"USE `{dbname}`;")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS notes (
                id INT AUTO_INCREMENT PRIMARY KEY,
                note VARCHAR(255) NOT NULL
            );
        """)
        logger.info("Step 5 SUCCESS: Notes table created/exists")

        cur.close()
        conn.close()
        logger.info("Database initialization completed successfully")
        return "Initialized labdb + notes table."
    except Exception as e:
        error_msg = f"Init failed at some step: {str(e)}"
        logger.error(f"{error_msg} | Error type: {type(e).__name__}")
        return f"{error_msg} | Type: {type(e).__name__}", 500

@app.route("/debug")
def debug():
    # origin_verified will be True if headers match the secret in Systemd
    sent_header = request.headers.get("X-Custom-Header")
    return jsonify({
        "headers": dict(request.headers),
        "origin_verified": sent_header == CF_PASSWORD,
        "match_details": f"Sent: {sent_header} | Expected: {CF_PASSWORD}"
    })

@app.route('/static/<path:filename>')
def custom_static(filename):
    """
    Custom static file handler that disables ETag and Last-Modified headers.
    This prevents cache misses caused by different ETags from multiple backend servers.
    """
    response = make_response(send_from_directory('/opt/rdsapp/static', filename))
    # Remove headers that cause cache revalidation issues with multiple backends
    response.headers.pop('ETag', None)
    response.headers.pop('Last-Modified', None)
    # CRITICAL: Override Cache-Control completely to allow CloudFront caching
    # Flask defaults to 'no-cache' which prevents CloudFront caching
    response.headers['Cache-Control'] = 'public, max-age=31536000, immutable'
    return response

@app.route("/add", methods=["POST", "GET"])
def add_note():
    note = request.args.get("note", "").strip()
    if not note:
        return "Missing note param. Try: /add?note=hello", 400
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("INSERT INTO notes(note) VALUES(%s);", (note,))
    cur.close()
    conn.close()
    return f"Inserted note: {note}"

@app.route("/api/public-feed")
def public_feed():
    """Cacheable public endpoint - origin tells CloudFront to cache for 30s via s-maxage"""
    now = datetime.now(timezone.utc)
    messages = [
        "The cloud never sleeps.",
        "Cache rules everything around me.",
        "s-maxage is for shared caches like CDNs.",
        "If the origin says cache, CloudFront obeys.",
        "Origin-driven caching: consent, not assumption.",
    ]
    response = make_response(jsonify({
        "server_time_utc": now.isoformat(),
        "message_of_the_minute": messages[now.minute % len(messages)],
        "cache_info": "This response is cacheable for 30s by CloudFront (s-maxage=30)"
    }))
    # s-maxage=30 tells shared caches (CloudFront) to cache for 30 seconds
    # max-age=0 tells the browser NOT to cache locally
    response.headers["Cache-Control"] = "public, s-maxage=30, max-age=0"
    return response

@app.route("/api/list")
@app.route("/list")
def list_notes():
    """Private endpoint - never cache (user-specific data)"""
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT note FROM notes ORDER BY id DESC;")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        response = make_response(f"<h3>Notes:</h3> {str(rows)}")
        response.headers["Cache-Control"] = "private, no-store"
        return response
    except Exception as e:
        return f"Error connecting to DB: {str(e)}", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
PY

# 4. Setup Systemd Service
cat >/etc/systemd/system/rdsapp.service <<SERVICE
[Unit]
Description=EC2 to RDS Notes App
After=network.target

[Service]
WorkingDirectory=/opt/rdsapp
Environment=SECRET_ID=${secret_name}
Environment=CF_PW=${cf_header_pw}
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable rdsapp
systemctl start rdsapp
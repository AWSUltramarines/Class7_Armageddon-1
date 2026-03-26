#!/bin/bash
dnf update -y
dnf install -y python3-pip
pip3 install flask pymysql boto3 watchtower

mkdir -p /opt/rdsapp
cat >/opt/rdsapp/app.py <<'PY'
import json
import os
import logging
from datetime import datetime, timezone
import boto3
import pymysql
import watchtower
from flask import Flask, request

REGION = boto3.session.Session().region_name or "us-east-1"
SECRET_ID = os.environ.get("SECRET_ID", "jasongeddon/rds/mysql")

# Configure CloudWatch logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("rdsapp")
logs_client = boto3.client("logs", region_name=REGION)
logger.addHandler(watchtower.CloudWatchLogHandler(
    log_group="/lab/rdsapp",
    stream_name="app-logs",
    create_log_group=False,
    boto3_client=logs_client
))

secrets = boto3.client("secretsmanager", region_name=REGION)

def get_db_creds():
    resp = secrets.get_secret_value(SecretId=SECRET_ID)
    s = json.loads(resp["SecretString"])
    # When you use "Credentials for RDS database", AWS usually stores:
    # username, password, host, port, dbname (sometimes)
    return s

def get_conn():
    c = get_db_creds()
    host = c["host"]
    user = c["username"]
    password = c["password"]
    port = int(c.get("port", 3306))
    db = c.get("dbname", "labdb")  # we'll create this if it doesn't exist
    try:
        conn = pymysql.connect(host=host, user=user, password=password, port=port, database=db, autocommit=True)
        logger.info("Database connection successful")
        return conn
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        raise

app = Flask(__name__)
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 86400  # 1 day — ensures CloudFront gets a cacheable response

@app.route("/")
def home():
    return """
    <h2>EC2 → RDS Notes App</h2>
    <p>POST /add?note=hello</p>
    <p>GET /list</p>
    """

@app.route("/init")
def init_db():
    c = get_db_creds()
    host = c["host"]
    user = c["username"]
    password = c["password"]
    port = int(c.get("port", 3306))

    # connect without specifying a DB first
    conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)
    cur = conn.cursor()
    cur.execute("CREATE DATABASE IF NOT EXISTS labdb;")
    cur.execute("USE labdb;")
    cur.execute("""
        CREATE TABLE IF NOT EXISTS notes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            note VARCHAR(255) NOT NULL
        );
    """)
    cur.close()
    conn.close()
    return "Initialized labdb + notes table."

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

@app.route("/list")
def list_notes():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT id, note FROM notes ORDER BY id DESC;")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    out = "<h3>Notes</h3><ul>"
    for r in rows:
        out += f"<li>{r[0]}: {r[1]}</li>"
    out += "</ul>"
    return out

@app.route("/api/public-feed")
def public_feed():
    data = json.dumps({
        "message of the minute": "i will succeed",
        "server_time_utc": datetime.now(timezone.utc).isoformat()
    })
    return app.response_class(
        response=data,
        status=200,
        mimetype="application/json",
        headers={"Cache-Control": "public, s-maxage=30, max-age=0"}
    )

@app.route("/api/user-feed")
def user_feed():
    data = json.dumps({
        "feed": "user",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "items": ["private-1", "private-2"]
    })
    return app.response_class(
        response=data,
        status=200,
        mimetype="application/json",
        headers={"Cache-Control": "private, no-store"}
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
PY

# Static file for CloudFront invalidation testing
mkdir -p /opt/rdsapp/static
echo "v1 — original item" > /opt/rdsapp/static/item.txt

cat >/etc/systemd/system/rdsapp.service <<'SERVICE'
[Unit]
Description=EC2 to RDS Notes App
After=network.target

[Service]
WorkingDirectory=/opt/rdsapp
Environment=SECRET_ID=jasongeddon/rds/mysql
Environment=AWS_DEFAULT_REGION=ap-northeast-1
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable rdsapp
systemctl start rdsapp
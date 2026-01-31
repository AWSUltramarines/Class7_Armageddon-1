#!/bin/bash
set -euo pipefail

# Logging configuration
LOG_FILE="/var/log/notes-app/user_data.log"
mkdir -p /var/log/notes-app
exec > >(tee -a "$LOG_FILE") 2>&1

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting user_data script execution..."

echo "$(date '+%Y-%m-%d %H:%M:%S') - Updating system packages..."
dnf update -y

echo "$(date '+%Y-%m-%d %H:%M:%S') - Installing required packages..."
dnf install -y python3-pip

echo "$(date '+%Y-%m-%d %H:%M:%S') - Installing Python packages..."
pip3 install flask pymysql boto3

# ======== CLOUDWATCH ADDITION START ========
echo "$(date '+%Y-%m-%d %H:%M:%S') - Installing CloudWatch Agent..."
dnf install -y amazon-cloudwatch-agent

echo "$(date '+%Y-%m-%d %H:%M:%S') - Creating application directory..."
mkdir -p /opt/rdsapp

echo "$(date '+%Y-%m-%d %H:%M:%S') - Creating Flask application..."
cat >/opt/rdsapp/app.py <<'PY'
import json
import os
import logging
import sys
import boto3
import pymysql
from flask import Flask, request

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/notes-app/app.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

REGION = os.environ.get("AWS_REGION", "us-east-2")
SECRET_ID = os.environ.get("SECRET_ID", "helga/rds/mysql")

secrets = boto3.client("secretsmanager", region_name=REGION)

def get_db_creds():
    resp = secrets.get_secret_value(SecretId=SECRET_ID)
    s = json.loads(resp["SecretString"])
    return s

def get_conn():
    c = get_db_creds()
    host = c["host"]
    user = c["username"]
    password = c["password"]
    port = int(c.get("port", 3306))
    db = c.get("dbname", "t_labdb")
    return pymysql.connect(host=host, user=user, password=password, port=port, database=db, autocommit=True)

app = Flask(__name__)

@app.route("/")
def home():
    return """
    <h2>EC2 → RDS Notes App</h2>
    <p>POST /add?note=hello</p>
    <p>GET /list</p>
    <p>GET /health</p>
    """

@app.route("/health")
def health():
    return {"status": "healthy", "service": "notes-app"}

@app.route("/init")
def init_db():
    c = get_db_creds()
    host = c["host"]
    user = c["username"]
    password = c["password"]
    port = int(c.get("port", 3306))

    conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)
    cur = conn.cursor()
    cur.execute("CREATE DATABASE IF NOT EXISTS t_labdb;")
    cur.execute("USE t_labdb;")
    cur.execute("""
        CREATE TABLE IF NOT EXISTS notes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            note VARCHAR(255) NOT NULL
        );
    """)
    cur.close()
    conn.close()
    logger.info("Database initialized successfully")
    return "Initialized t_labdb + notes table."

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
    logger.info(f"Added note: {note[:50]}...")
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
    logger.info(f"Listed {len(rows)} notes")
    return out

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80, debug=True)
PY

echo "$(date '+%Y-%m-%d %H:%M:%S') - Creating CloudWatch Agent configuration..."
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root",
        "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/notes-app/user_data.log",
                        "log_group_name": "/helga/ec2/user-data",
                        "log_stream_name": "{instance_id}",
                        "retention_in_days": 7
                    },
                    {
                        "file_path": "/var/log/notes-app/app.log",
                        "log_group_name": "/helga/notes-app",
                        "log_stream_name": "{instance_id}",
                        "retention_in_days": 7
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "Lab1C/EC2",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["disk_used_percent"],
                "resources": ["/"],
                "metrics_collection_interval": 60
            }
        },
        "append_dimensions": {
            "InstanceId": "${aws:InstanceId}"
        }
    }
}
CWCONFIG

echo "$(date '+%Y-%m-%d %H:%M:%S') - Creating systemd service..."
cat >/etc/systemd/system/rdsapp.service <<'SERVICE'
[Unit]
Description=EC2 to RDS Notes App
After=network.target

[Service]
WorkingDirectory=/opt/rdsapp
Environment=SECRET_ID=helga/rds/mysql
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

echo "$(date '+%Y-%m-%d %H:%M:%S') - Reloading systemd daemon..."
systemctl daemon-reload

echo "$(date '+%Y-%m-%d %H:%M:%S') - Enabling rdsapp service..."
systemctl enable rdsapp

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting rdsapp service..."
systemctl start rdsapp

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting CloudWatch Agent..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

echo "$(date '+%Y-%m-%d %H:%M:%S') - Enabling CloudWatch Agent to start on boot..."
systemctl enable amazon-cloudwatch-agent

echo "$(date '+%Y-%m-%d %H:%M:%S') - User data script completed successfully!"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Notes app is running on port 80"
echo "$(date '+%Y-%m-%d %H:%M:%S') - CloudWatch Agent is running and collecting metrics/logs"
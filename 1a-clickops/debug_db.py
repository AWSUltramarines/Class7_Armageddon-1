import boto3
import json
import pymysql # Use psycopg2 if using Postgres
import socket
import sys

# --- CONFIGURATION ---
SECRET_NAME = "arma-g-02"  # Your exact secret name
REGION = "us-east-1"           # Your AWS Region

def test_connectivity(host, port):
    print(f"\n[2] TESTING NETWORK CONNECTIVITY to {host}:{port}...")
    try:
        sock = socket.create_connection((host, port), timeout=5)
        print("   SUCCESS: TCP connection established. Security Groups are correct.")
        sock.close()
        return True
    except socket.error as e:
        print(f"   FAILURE: Could not connect to {host}:{port}.")
        print(f"   ERROR: {e}")
        print("   HINT: Check your Security Groups. EC2 must be allowed in RDS Inbound Rules.")
        return False

def get_secret():
    print(f"\n[1] TESTING SECRET RETRIEVAL for '{SECRET_NAME}'...")
    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager', region_name=REGION)

    try:
        get_secret_value_response = client.get_secret_value(SecretId=SECRET_NAME)
        print("   SUCCESS: Secret retrieved from AWS.")
        
        # Parse the secret JSON
        if 'SecretString' in get_secret_value_response:
            secret = json.loads(get_secret_value_response['SecretString'])
            return secret
    except Exception as e:
        print(f"   FAILURE: Could not retrieve secret.")
        print(f"   ERROR: {e}")
        print("   HINT: Check IAM Role permissions or Secret Name.")
        return None

def test_login(secret):
    print(f"\n[3] TESTING DATABASE LOGIN...")
    try:
        # Aurora MySQL Default Port is 3306
        conn = pymysql.connect(
            host=secret['host'],
            user=secret['username'],
            password=secret['password'],
            port=int(secret.get('port', 3306)),
            connect_timeout=5
        )
        print("   SUCCESS: Successfully logged into the database!")
        conn.close()
    except Exception as e:
        print("   FAILURE: Login rejected.")
        print(f"   ERROR: {e}")
        print("   HINT: Check if the password in the Secret matches the RDS instance.")

if __name__ == "__main__":
    secret = get_secret()
    if secret:
        # Assuming the secret has standard keys: host, username, password
        # If your secret just has raw JSON, adjust keys below
        host = secret.get('host') 
        port = int(secret.get('port', 3306))
        
        if test_connectivity(host, port):
            test_login(secret)
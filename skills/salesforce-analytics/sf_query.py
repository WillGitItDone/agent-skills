#!/usr/bin/env python3
"""
Salesforce READ-ONLY query tool for the salesforce-analytics skill.

⚠️  This script ONLY performs:
    - OAuth2 authentication (POST to /services/oauth2/token — required for auth)
    - SOQL SELECT queries via GET /services/data/vXX.0/query

It NEVER creates, updates, or deletes any Salesforce record.
"""

import json
import os
import sys
import urllib.request
import urllib.parse
import urllib.error
from datetime import datetime, timedelta


API_VERSION = "v60.0"


def load_env():
    """Load credentials from the env file."""
    env_path = os.path.expanduser("~/.config/engrain/salesforce.env")
    creds = {}
    if os.path.exists(env_path):
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, val = line.split("=", 1)
                    creds[key.strip()] = val.strip()
    return creds


def authenticate(creds):
    """Authenticate via OAuth2 Username-Password flow. Returns access token and instance URL."""
    token_url = "https://login.salesforce.com/services/oauth2/token"

    params = urllib.parse.urlencode({
        "grant_type": "password",
        "client_id": creds["SALESFORCE_CONSUMER_KEY"],
        "client_secret": creds["SALESFORCE_CONSUMER_SECRET"],
        "username": creds["SALESFORCE_USERNAME"],
        "password": creds.get("SALESFORCE_PASSWORD", "") + creds["SALESFORCE_SECURITY_TOKEN"],
    }).encode()

    req = urllib.request.Request(token_url, data=params, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")

    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode())
            return data["access_token"], data["instance_url"]
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"Authentication failed ({e.code}): {body}", file=sys.stderr)
        sys.exit(1)


def soql_query(access_token, instance_url, query):
    """Execute a SOQL SELECT query. Returns all records (handles pagination)."""
    records = []
    url = f"{instance_url}/services/data/{API_VERSION}/query?q={urllib.parse.quote(query)}"

    while url:
        req = urllib.request.Request(url, method="GET")
        req.add_header("Authorization", f"Bearer {access_token}")
        req.add_header("Accept", "application/json")

        try:
            with urllib.request.urlopen(req) as resp:
                data = json.loads(resp.read().decode())
                records.extend(data.get("records", []))

                # Handle pagination
                next_url = data.get("nextRecordsUrl")
                url = f"{instance_url}{next_url}" if next_url else None
        except urllib.error.HTTPError as e:
            body = e.read().decode()
            print(f"Query failed ({e.code}): {body}", file=sys.stderr)
            sys.exit(1)

    return records


def main():
    if len(sys.argv) < 2:
        print("Usage: sf_query.py [auth|query] [options]", file=sys.stderr)
        sys.exit(1)

    command = sys.argv[1]
    creds = load_env()

    if not creds.get("SALESFORCE_CONSUMER_KEY"):
        print("Error: Credentials not found. Check ~/.config/engrain/salesforce.env", file=sys.stderr)
        sys.exit(1)

    if command == "auth":
        # Test authentication and print instance info
        access_token, instance_url = authenticate(creds)
        print(json.dumps({
            "status": "authenticated",
            "instance_url": instance_url,
            "api_version": API_VERSION,
        }))

    elif command == "query":
        # Parse options
        days = 30
        fields = "Id,Subject,Description,Status,Priority,CreatedDate,CaseNumber,Type,Reason"

        i = 2
        while i < len(sys.argv):
            if sys.argv[i] == "--days" and i + 1 < len(sys.argv):
                days = int(sys.argv[i + 1])
                i += 2
            elif sys.argv[i] == "--fields" and i + 1 < len(sys.argv):
                fields = sys.argv[i + 1]
                i += 2
            elif sys.argv[i] == "--soql" and i + 1 < len(sys.argv):
                # Allow raw SOQL (must be SELECT only)
                raw_soql = sys.argv[i + 1]
                if not raw_soql.strip().upper().startswith("SELECT"):
                    print("Error: Only SELECT queries allowed (READ-ONLY).", file=sys.stderr)
                    sys.exit(1)
                access_token, instance_url = authenticate(creds)
                records = soql_query(access_token, instance_url, raw_soql)
                print(json.dumps(records, indent=2, default=str))
                return
            else:
                i += 1

        # Build date filter
        since_date = (datetime.utcnow() - timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%SZ")

        # Build SOQL — SELECT ONLY
        soql = f"SELECT {fields} FROM Case WHERE CreatedDate >= {since_date} ORDER BY CreatedDate DESC"

        access_token, instance_url = authenticate(creds)
        records = soql_query(access_token, instance_url, soql)

        # Output as JSON
        print(json.dumps(records, indent=2, default=str))

    else:
        print(f"Unknown command: {command}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3

import datetime
import jwt
import requests
import os
from dotenv import load_dotenv


load_dotenv()

issuer_id = os.getenv("APP_STORE_CONNECT_ISSUER")
app_id = os.getenv("APP_STORE_CONNECT_APP_ID")
key_id = os.getenv("APP_STORE_CONNECT_API_KEY")
HOME = os.getenv("HOME")

private_key_path = "{}/private_keys/AuthKey_{}.p8".format(HOME, key_id)
platform = os.getenv("PLATFORM")

BASE_URL = "https://api.appstoreconnect.apple.com/v1"
EXPIRY = 60

with open(private_key_path, "r+b") as f:
    private_key = f.read()

expiration_time = datetime.datetime.now(tz=datetime.timezone.utc) + datetime.timedelta(
    seconds=EXPIRY
)
encoded_jwt = jwt.encode(
    {"iss": issuer_id, "exp": expiration_time, "aud": "appstoreconnect-v1"},
    private_key,
    algorithm="ES256",
    headers={
        "alg": "ES256",
        "kid": key_id,
        "typ": "JWT",
    },
)

headers = {"Authorization": f"Bearer {encoded_jwt}"}

build_number = 0
try:
    r = requests.get(
        f"{BASE_URL}/preReleaseVersions",
        headers=headers,
        params={
            "limit": 1,
            "filter[app]": app_id,
            "filter[platform]": platform,
        },
    ).json()
    build_id = r["data"][0]["id"]
    build_name = r["data"][0]["attributes"]["version"]

    r = requests.get(
        f"{BASE_URL}/preReleaseVersions/{build_id}/builds", headers=headers
    ).json()
    build_number = r["data"][0]["attributes"]["version"]
except Exception as e:
    pass

build_number = int(build_number) + 1

print(build_number)

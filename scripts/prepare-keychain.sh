#!/bin/bash

echo $CERTIFICATE | base64 -d > certificate.p12
echo $CERTIFICATE_DEVELOPER_ID | base64 -d > certificate_developer_id.p12
echo $INSTALLER_CERTIFICATE | base64 -d > installer_certificate.p12
security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
security default-keychain -s build.keychain
security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
security import certificate.p12 -k build.keychain -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
security import certificate_developer_id.p12 -k build.keychain -P "$DEVELOPER_ID_PASSWORD" -T /usr/bin/codesign
security import installer_certificate.p12 -k build.keychain -P "$INSTALLER_CERTIFICATE_PASSWORD" -T /usr/bin/productbuild
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" build.keychain

mkdir -p ~/private_keys
echo $APP_STORE_CONNECT_PRIVATE_KEY | base64 -d > ~/private_keys/AuthKey_${APP_STORE_CONNECT_API_KEY}.p8

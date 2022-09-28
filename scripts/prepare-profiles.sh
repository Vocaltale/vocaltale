#!/bin/bash

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles

echo $MACOS_PROVISION_PROFILE | base64 -d > ~/Library/MobileDevice/Provisioning\ Profiles/macos.provisionprofile
echo $DEVELOPER_ID_PROVISION_PROFILE | base64 -d > ~/Library/MobileDevice/Provisioning\ Profiles/developer-id.provisionprofile
echo $IOS_PROVISION_PROFILE | base64 -d > ~/Library/MobileDevice/Provisioning\ Profiles/ios.mobileprovision
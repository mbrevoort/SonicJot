#!/bin/bash

echo "Stage: PRE-Xcode Build is activated .... "

# for future reference
# https://developer.apple.com/documentation/xcode/environment-variable-reference

cd ../SonicJot/

plutil -replace MIXPANEL_PROJECT_TOKEN -string $MIXPANEL_PROJECT_TOKEN Info.plist

plutil -p Info.plist

echo "Stage: PRE-Xcode Build is DONE .... "

exit 0

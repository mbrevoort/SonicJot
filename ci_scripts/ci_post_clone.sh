#!/bin/sh

#  ci_post_clone.sh
#  SonicJot
#
#  Created by Mike Brevoort on 2/4/24.
#  

# Ignore macro validation https://stackoverflow.com/questions/77267883/how-do-i-trust-a-swift-macro-target-for-xcode-cloud-builds
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

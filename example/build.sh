#!/bin/sh

set -euxo pipefail

xcodebuild \
  -workspace example.xcworkspace \
  build \
  -scheme example -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
  \
  | xcbeautify
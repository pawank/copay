#!/bin/bash - 

echo "Starting release builds.."
#flutter run --release
#flutter build apk --debug
flutter build appbundle
flutter build apk --split-per-abi
cp build/app/outputs/apk/release/app-armeabi-v7a-release.apk ~/Downloads/app.apk
cp build/app/outputs/apk/release/app-release.apk ~/Downloads/
cp build/app/outputs/bundle/release/app.aab ~/Downloads/

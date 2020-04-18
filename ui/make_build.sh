#!/bin/bash - 

echo "Starting release builds.."
#flutter run --release
#flutter build apk --debug
flutter build appbundle
flutter build apk --split-per-abi

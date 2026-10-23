#!/bin/sh
# Installs the Expo / React Native packages with versions that match each
# other. `expo install` resolves the right versions for the installed SDK,
# so nothing is pinned by hand here.
set -e
npm install
npx expo install expo expo-router react react-native react-native-safe-area-context \
  react-native-screens expo-status-bar expo-document-picker expo-image-picker \
  expo-sharing expo-file-system expo-asset expo-font expo-localization \
  @react-native-async-storage/async-storage
npm install zustand @react-native-ml-kit/text-recognition
npm install -D @types/react
echo "Done. OCR needs a development build: npx expo prebuild && npx expo run:android"

#!/bin/bash

# Script to generate a release keystore for Android app signing
# This script should be run in the android/app directory

echo "Generating release keystore..."

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "Error: keytool is not available. Please ensure Java JDK is installed."
    exit 1
fi

# Generate the keystore
keytool -genkeypair \
    -v \
    -keystore release.keystore \
    -storepass daily_inc_release \
    -alias daily_inc_key \
    -keypass daily_inc_release \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Daily Inc, OU=Development, O=Daily Inc, L=Unknown, S=Unknown, C=US"

echo "Release keystore generated successfully!"
echo "Keystore location: android/app/release.keystore"
echo "Store password: daily_inc_release"
echo "Key alias: daily_inc_key"
echo "Key password: daily_inc_release"
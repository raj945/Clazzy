#!/bin/bash

# Exit on error
set -e

# Clone Flutter SDK to a local folder in the build container
echo "Downloading Flutter SDK..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable

# Add Flutter bin to the path
export PATH="$PATH:`pwd`/flutter/bin"

echo "Checking Flutter installation..."
flutter doctor

# Enable web support
flutter config --enable-web

# Build the release web app
echo "Building Flutter Web application..."
flutter build web --release

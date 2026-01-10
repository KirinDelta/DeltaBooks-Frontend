#!/bin/bash

# Quick start script for DeltaBooks Frontend

echo "🚀 Starting DeltaBooks Frontend..."
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo ""
    echo "Please install Flutter first:"
    echo "1. Download from: https://docs.flutter.dev/get-started/install/macos"
    echo "2. Extract and add to PATH"
    echo "3. Run: flutter doctor"
    echo ""
    exit 1
fi

# Check if backend is running
echo "Checking backend connection..."
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Backend is running on localhost:3000"
else
    echo "⚠️  Warning: Backend doesn't seem to be running on localhost:3000"
    echo "   Make sure your backend is started before testing the app"
fi

echo ""
echo "Installing dependencies..."
flutter pub get

echo ""
echo "Available devices:"
flutter devices

echo ""
echo "Starting the app..."
echo "Press 'r' for hot reload, 'R' for hot restart, 'q' to quit"
echo ""

# Try to run on available device
flutter run

# DeltaBooks Frontend Setup Guide

## Prerequisites

1. **Install Flutter**
   - Download Flutter SDK from: https://docs.flutter.dev/get-started/install/macos
   - Extract it to a location like `~/development/flutter` or `/usr/local/flutter`
   - Add Flutter to your PATH by adding this to your `~/.zshrc`:
     ```bash
     export PATH="$PATH:$HOME/development/flutter/bin"
     ```
   - Then run: `source ~/.zshrc`
   - Verify installation: `flutter doctor`

2. **Install Dependencies**
   ```bash
   cd /Users/kirin/Projects/DeltaBooks/frontend
   flutter pub get
   ```

## Running the App

### Option 1: Run on iOS Simulator (macOS)
```bash
# Open iOS Simulator
open -a Simulator

# Run the app
flutter run
```

### Option 2: Run on Android Emulator
```bash
# Start an Android emulator (if you have Android Studio installed)
# Then run:
flutter run
```

### Option 3: Run on Web Browser
```bash
flutter run -d chrome
```

### Option 4: Run on Physical Device
- For iOS: Connect your iPhone via USB, enable Developer Mode, and run `flutter run`
- For Android: Enable USB debugging on your device, connect via USB, and run `flutter run`

## Available Devices

Check available devices with:
```bash
flutter devices
```

## Hot Reload

While the app is running:
- Press `r` in the terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

## Backend Connection

The app is configured to connect to `http://localhost:3000` (as set in `lib/services/api_service.dart`).

**Note for iOS Simulator/Physical Device:**
- iOS Simulator: `localhost:3000` should work
- Physical iOS Device: You may need to use your Mac's IP address instead of `localhost`
- Android Emulator: Use `10.0.2.2` instead of `localhost:3000`
- Physical Android Device: Use your Mac's IP address

To find your Mac's IP address:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

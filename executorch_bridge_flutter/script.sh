#!/bin/bash

set -e  # Exit on error

echo "🚀 Starting Swift Package Manager migration..."

# Store the root directory
ROOT_DIR="/Users/sam/Desktop/twyns/executorch_bridge_flutter"
cd "$ROOT_DIR"

# Step 1: Copy Messages.g.swift to Swift Package location
echo "📦 Step 1: Copying Messages.g.swift to Swift Package location..."
if [ -f "ios/Classes/Messages.g.swift" ]; then
    cp ios/Classes/Messages.g.swift ios/executorch_bridge_flutter/Sources/executorch_bridge_flutter/
    echo "✅ Messages.g.swift copied successfully"
else
    echo "⚠️  Warning: ios/Classes/Messages.g.swift not found"
fi

# Step 2: Verify file structure
echo ""
echo "📋 Step 2: Verifying Swift Package structure..."
if [ -f "ios/executorch_bridge_flutter/Sources/executorch_bridge_flutter/Messages.g.swift" ] && \
   [ -f "ios/executorch_bridge_flutter/Sources/executorch_bridge_flutter/ExecutorchBridgeFlutterPlugin.swift" ]; then
    echo "✅ Swift Package structure verified"
    ls -la ios/executorch_bridge_flutter/Sources/executorch_bridge_flutter/
else
    echo "❌ Error: Swift Package structure incomplete"
    exit 1
fi

# Step 3: Deintegrate CocoaPods from example
echo ""
echo "🧹 Step 3: Removing CocoaPods from example app..."
cd "$ROOT_DIR/example/ios"

if command -v pod &> /dev/null; then
    if [ -f "Podfile" ]; then
        pod deintegrate || true
        echo "✅ CocoaPods deintegrated"
    fi
else
    echo "⚠️  CocoaPods not installed, skipping deintegration"
fi

# Remove CocoaPods files
rm -f Podfile
rm -f Podfile.lock
rm -rf Pods/
echo "✅ CocoaPods files removed"

# Step 4: Clean xcconfig files
echo ""
echo "🔧 Step 4: Cleaning xcconfig files..."

# Backup and clean Debug.xcconfig
if [ -f "Flutter/Debug.xcconfig" ]; then
    cp Flutter/Debug.xcconfig Flutter/Debug.xcconfig.backup
    grep -v "Pods" Flutter/Debug.xcconfig > Flutter/Debug.xcconfig.tmp || true
    mv Flutter/Debug.xcconfig.tmp Flutter/Debug.xcconfig
    echo "✅ Debug.xcconfig cleaned"
fi

# Backup and clean Release.xcconfig
if [ -f "Flutter/Release.xcconfig" ]; then
    cp Flutter/Release.xcconfig Flutter/Release.xcconfig.backup
    grep -v "Pods" Flutter/Release.xcconfig > Flutter/Release.xcconfig.tmp || true
    mv Flutter/Release.xcconfig.tmp Flutter/Release.xcconfig
    echo "✅ Release.xcconfig cleaned"
fi

# Step 5: Clean and rebuild
echo ""
echo "🔨 Step 5: Cleaning and rebuilding..."
cd "$ROOT_DIR/example"

flutter clean
echo "✅ Flutter clean completed"

flutter pub get
echo "✅ Dependencies fetched"

# Step 6: Optional - remove old Classes directory
echo ""
echo "🗑️  Step 6: Cleaning up old CocoaPods structure..."
cd "$ROOT_DIR"

if [ -d "ios/Classes" ]; then
    echo "⚠️  Found ios/Classes directory"
    echo "   This is the old CocoaPods structure and can be removed."
    echo "   Keeping it for now - you can manually remove it later if needed."
    # Uncomment to auto-remove:
    # rm -rf ios/Classes
fi

echo ""
echo "✅ Migration complete!"
echo ""
echo "Next steps:"
echo "1. Try building: cd example && flutter run"
echo "2. If you get errors, open example/ios/Runner.xcworkspace in Xcode"
echo "3. In Xcode, clean build folder (Cmd+Shift+K) and rebuild"
echo ""
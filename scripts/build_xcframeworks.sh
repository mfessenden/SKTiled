#! /bin/sh -e


# Release dir path
PROJECT_PATH=$PWD
BUILD_DIR=${PROJECT_PATH}/build
ARCHIVE_DIR=${BUILD_DIR}/archives


echo "▸ Cleaning build dir: '${BUILD_DIR}''"
rm -rf $BUILD_DIR
mkdir $BUILD_DIR
mkdir $ARCHIVE_DIR


# archive the various platforms...
xcodebuild archive \
-project SKTiled.xcodeproj \
-scheme SKTiled-macOS \
-destination "generic/platform=macOS" \
-archivePath ${ARCHIVE_DIR}/SKTiled-macOS \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES


xcodebuild archive \
-project SKTiled.xcodeproj \
-scheme SKTiled-iOS \
-destination "generic/platform=iOS" \
-archivePath ${ARCHIVE_DIR}/SKTiled-iOS \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES


xcodebuild archive \
-project SKTiled.xcodeproj \
-scheme SKTiled-iOS \
-destination "generic/platform=iOS Simulator" \
-archivePath ${ARCHIVE_DIR}/SKTiled-iOS-Sim \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES


xcodebuild archive \
-project SKTiled.xcodeproj \
-scheme SKTiled-tvOS \
-destination "generic/platform=tvOS" \
-archivePath ${ARCHIVE_DIR}/SKTiled-tvOS \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES


xcodebuild archive \
-project SKTiled.xcodeproj \
-scheme SKTiled-tvOS \
-destination "generic/platform=tvOS Simulator" \
-archivePath ${ARCHIVE_DIR}/SKTiled-tvOS-Sim \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES


# create the xcframework
xcodebuild -create-xcframework \
-framework ${ARCHIVE_DIR}/SKTiled-macOS.xcarchive/Products/Library/Frameworks/SKTiled.framework \
-framework ${ARCHIVE_DIR}/SKTiled-iOS.xcarchive/Products/Library/Frameworks/SKTiled.framework \
-framework ${ARCHIVE_DIR}/SKTiled-iOS-Sim.xcarchive/Products/Library/Frameworks/SKTiled.framework \
-framework ${ARCHIVE_DIR}/SKTiled-tvOS.xcarchive/Products/Library/Frameworks/SKTiled.framework \
-framework ${ARCHIVE_DIR}/SKTiled-tvOS-Sim.xcarchive/Products/Library/Frameworks/SKTiled.framework \
-output ${BUILD_DIR}/SKTiled.xcframework

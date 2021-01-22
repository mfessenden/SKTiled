#! /bin/sh -e
#
# Description:
#    This script creates a binary framework for use with all supported platforms & architectures.


# Release dir path
PROJECT_PATH=$PWD
BUILD_DIR=${PROJECT_PATH}/build
ARCHIVE_DIR=${BUILD_DIR}/archives
FRAMEWORKS_DIR=${PROJECT_PATH}/Frameworks
FRAMEWORK_FILE=${FRAMEWORKS_DIR}/SKTiled.xcframework


echo "▸ cleaning build dir: '${BUILD_DIR}''"
rm -rf $BUILD_DIR
mkdir $BUILD_DIR
mkdir $ARCHIVE_DIR
mkdir $FRAMEWORKS_DIR

# archive the various platforms...
xcodebuild archive \
-project SKTiled.xcodeproj \
-scheme SKTiled-macOS \
-destination "generic/platform=macOS" \
#-destination 'platform=macOS,arch=x86_64,variant=Mac Catalyst' \
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


# move & cleanup
mv ${BUILD_DIR}/SKTiled.xcframework $FRAMEWORK_FILE;
#rm -rf $BUILD_DIR

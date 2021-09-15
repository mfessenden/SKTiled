#! /bin/sh
#
# Description:
#    This script creates a binary framework for use with all supported platforms & architectures.

HELP="

build-xcframeworks -- build binary frameworks script.

Usage:  build-xcframeworks [command]

Options (general):
  -h, --help      print help message.
  -c, --clean     clean the build directories on exit.
  -o, --output    xcframework output path.
"


# Release dir path
PROJECT_PATH=$PWD
BUILD_DIR=${PROJECT_PATH}/build
ARCHIVE_DIR=${BUILD_DIR}/archives
FRAMEWORKS_DIR=${BUILD_DIR}/Frameworks
FRAMEWORK_FILE=${FRAMEWORKS_DIR}/SKTiled.xcframework


# parse arguments
CLEAN_BUILD_DIRS=0
PARAMS=""
while (( "$#" )); do
  case "$1" in
      -h|--help)
        printf '%s' "$HELP"
        exit 0
        shift
        ;;
    -c|--clean)
      CLEAN_BUILD_DIRS=1
      shift
      ;;
    -o|--output)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        OUTPUT_PATH=$2
        FRAMEWORK_FILE=${OUTPUT_PATH}/SKTiled.xcframework
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# set positional arguments in their proper place
eval set -- "$PARAMS"

# remove the build dir if it exists
if [ -d $BUILD_DIR ]
then
  rm -rf $BUILD_DIR
fi

# remove the output file if it already exists
if [ -d $FRAMEWORK_FILE ]
then
  rm -rf "$FRAMEWORK_FILE"
fi


mkdir $BUILD_DIR
mkdir $ARCHIVE_DIR

if [ ! -d $FRAMEWORKS_DIR ]
then
  mkdir $FRAMEWORKS_DIR
fi


# archive the various platforms...
xcodebuild archive \
-project SKTiled.xcodeproj \
-scheme SKTiled-macOS \
-destination "generic/platform=macOS" \
-archivePath ${ARCHIVE_DIR}/SKTiled-macOS \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcpretty


xcodebuild archive \
-project SKTiled.xcodeproj \
-scheme SKTiled-iOS \
-destination "generic/platform=iOS" \
-archivePath ${ARCHIVE_DIR}/SKTiled-iOS \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcpretty


xcodebuild archive \
-project SKTiled.xcodeproj \
-scheme SKTiled-iOS \
-destination "generic/platform=iOS Simulator" \
-archivePath ${ARCHIVE_DIR}/SKTiled-iOS-Sim \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcpretty


xcodebuild archive \
-project SKTiled.xcodeproj \
-scheme SKTiled-tvOS \
-destination "generic/platform=tvOS" \
-archivePath ${ARCHIVE_DIR}/SKTiled-tvOS \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcpretty


xcodebuild archive \
-project SKTiled.xcodeproj \
-scheme SKTiled-tvOS \
-destination "generic/platform=tvOS Simulator" \
-archivePath ${ARCHIVE_DIR}/SKTiled-tvOS-Sim \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcpretty


# create the xcframework
xcodebuild -create-xcframework \
-framework ${ARCHIVE_DIR}/SKTiled-macOS.xcarchive/Products/Library/Frameworks/SKTiled.framework \
-framework ${ARCHIVE_DIR}/SKTiled-iOS.xcarchive/Products/Library/Frameworks/SKTiled.framework \
-framework ${ARCHIVE_DIR}/SKTiled-iOS-Sim.xcarchive/Products/Library/Frameworks/SKTiled.framework \
-framework ${ARCHIVE_DIR}/SKTiled-tvOS.xcarchive/Products/Library/Frameworks/SKTiled.framework \
-framework ${ARCHIVE_DIR}/SKTiled-tvOS-Sim.xcarchive/Products/Library/Frameworks/SKTiled.framework \
-output ${BUILD_DIR}/SKTiled.xcframework | xcpretty


# move the resulting framework to the output directory
mv ${BUILD_DIR}/SKTiled.xcframework $FRAMEWORK_FILE

if [ -d $FRAMEWORK_FILE ]
then
  echo "▶︎ writing xcframework to '${FRAMEWORK_FILE}'"
else
    echo "Error creating framework file '${FRAMEWORK_FILE}'"
    exit 1
fi

# cleanup build directory on exit
if [ $CLEAN_BUILD_DIRS = 1 ]
then
  echo "▶︎ cleaning up archives '${BUILD_DIR}'"
  rm -rf "$BUILD_DIR"
fi

#!/bin/bash

# exit when any command fails
set -e

# check jazzy is installed
if ! command -v jazzy &> /dev/null
then
    echo "Error: 'jazzy' is not installed. Please see https://github.com/realm/jazzy"
    exit 126
fi


# specify custom config (or use default)
CFG_FILE=$1
CFG_FILE=".${CFG_FILE:-jazzy}.yaml"


# allow user to specify a browser ( for Chrome use `Google Chrome`)
BROWSER=$2
BROWSER="${BROWSER:-Safari}"


PROJECT_DIR=$PWD
HTML_DIR=$PWD/Docs/html
IMG_SRC_DIR=$PWD/Docs/images/
IMG_DEST_DIR=$HTML_DIR/images
INDEX_PAGE=$HTML_DIR/index.html


function imageSync() {
    echo "# syncing images: $IMG_SRC_DIR -> $IMG_DEST_DIR"
	rsync --exclude "src" \
        --exclude "hires" \
        --exclude "psd" \
		--exclude "*.psd" \
        --exclude "*.aseprite" \
        --exclude "*.ase" \
		-auvh --no-perms $IMG_SRC_DIR $IMG_DEST_DIR;
}

# run the jazzy command
jazzy --config "$CFG_FILE" ;

# create the images directory
[ -d $IMG_DEST_DIR ] || mkdir $IMG_DEST_DIR

# rsync images
imageSync;


open -a "$BROWSER" $INDEX_PAGE;

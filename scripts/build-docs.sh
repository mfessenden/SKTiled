#!/bin/bash

# specify custom config (or use default)
CFG_FILE=$1
CFG_FILE=".${CFG_FILE:-jazzy}.yaml"


THEME_DIR=$2
THEME_DIR="${THEME_DIR:-Docs/Themes/sktiled}"


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
jazzy --theme "$THEME_DIR" --config "$CFG_FILE" ;


# create the images directory
[ -d $IMG_DEST_DIR ] || mkdir $IMG_DEST_DIR

# rsync images
imageSync;

# open the result
open $INDEX_PAGE;

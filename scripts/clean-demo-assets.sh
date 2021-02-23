#!/usr/bin/env bash
# remove xattrs from assets
xattr -rc $PROJECT_DIR/Demo/Assets/.
echo "cleaning project assets: $PROJECT_DIR/Demo/Assets"

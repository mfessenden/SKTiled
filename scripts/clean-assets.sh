#!/usr/bin/env bash
# remove xattrs from assets
xattr -rc $PROJECT_DIR/Assets/.
echo "cleaning project assets: $PROJECT_DIR/Assets"

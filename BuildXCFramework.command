#!/bin/sh
# Wrapper for the  xcframework builder script. Can be run from the Finder.

projdir=`dirname "$0"`;
scriptdir=$projdir/scripts;

# change directory to project root
cd $projdir;

# run the `build-docs` script
sh $scriptdir/build-xcframeworks.sh;

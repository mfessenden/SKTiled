#!/bin/sh
# Simple wrapper for the Jazzy doc builder script. Can be run from the Finder.

projdir=`dirname "$0"`;
scriptdir=$projdir/scripts;

# change directory to project root
cd $projdir;

# run the `build-docs` script
sh $scriptdir/build-documentation.sh;

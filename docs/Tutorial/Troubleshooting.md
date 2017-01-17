# Troubleshooting

- [Linking Errors](#linking-errors)
- [XML Parsing Errors](#xml-parsing-errors)
- [Code Signing Errors](#code-signing-errors)

## Linking Errors

If you get a zlib import error, make sure you have linked zlib in your Xcode project:


*Project > Build Settings > Swift Compiler - Search Paths > Import Paths*

Add a path that represents the SKTiled zlib module:

`$(SRCROOT)/Sources`


![zlib compression](images/zlib_linking.png)

In your Xcode project file, the path entry will look like this:

`SWIFT_INCLUDE_PATHS = "zlib";`


## XML Parsing Errors

Sometimes the XML parser will throw errors with external tilesets that have been downloaded from the internet. Importing & re-exporting the tileset should make the error go away.


## Code Signing Errors

Occasionally you'll get a code signing error when compiling on OSX:

![Codesign Error](images/codesign-error.png)

If you're using Photoshop to save images, you might need to cleanup Finder metadata. To check, browse to your images directory in shell and run the following command:
 
    ls -al@

If any of your files have extra metadata that Xcode doesn't like, you'll see it listed below the file name:

![Image Metadata](images/xattr-cleanup.png)

Running the following command will clean up the extra data:

    xattr -c *.png


Next: [Getting Started](getting-started.html) - [Index](Tutorial.html)

# Troubleshooting

### zlib Errors

If you get a zlib import error, make sure you have linked zlib in your Xcode project:


*Project > Build Settings > Swift Compiler - Search Paths > Import Paths*

Add a path that represents the SKTiled zlib module:

`$(SRCROOT)/Sources`


![zlib compression](https://raw.githubusercontent.com/mfessenden/SKTiled/iOS10/docs/Images/zlib_linking.png)


### XML Parsing Errors

Sometimes the XML parser will throw errors with external tilesets that have been downloaded from the internet. Importing & re-exporting the tileset should make the error go away.


### Code Signing Errors

Occasionally you'll get a code signing error when compiling on OSX:

![Codesign Error](https://raw.githubusercontent.com/mfessenden/SKTiled/iOS10/docs/Images/codesign-error.png)

If you're using Photoshop to save images, you might need to cleanup Finder metadata. To check, browse to your images directory in shell and run the following command:
 
    ls -al@

If any of your files have extra metadata that Xcode doesn't like, you'll see it listed below the file name:

![Image Metadata](https://raw.githubusercontent.com/mfessenden/SKTiled/iOS10/docs/Images/xattr-cleanup.png)

Running the following command will clean up the extra data:

    xattr -c *.png



Next: [Getting Started](getting-started.html) - [Index](Tutorial.html)

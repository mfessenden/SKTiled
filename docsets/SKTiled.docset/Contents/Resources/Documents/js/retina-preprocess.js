
// preprocessor to add attributes for retina.js
$(document).ready(function(){
   $('img').each(function(index, item) {
       // string
       var imgSrc = item.src
       let fparts = imgSrc.split('.')

       if (fparts.length == 2) {
           let fname = fparts[0]
           let fext = fparts[1]

           if (fext == "png") {
               console.log('-> image: ' + imgSrc)
               $(item).attr( "data-rjs", "3" )
           }

       }

    });
});


function fileExists(fileName) {
    $.get(fileName, function(data, textStatus) {
        if (textStatus == "success") {
            // execute a success code
            console.log("file loaded!");
        }
    });
}

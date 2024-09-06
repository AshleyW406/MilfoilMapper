$(document).ready(function() {
  
  function moveImageBasedOnViewport() {
    var viewportWidth = $(window).width();
    
    if (viewportWidth < 970) {
      // Move the image to a new location when viewport is less than 970px
      $("#combined_logos > img").appendTo("#suggestions");
      $("#title").css("width",  "100%");
      $("#title").css("min-width",  "100%");
    } else {
      // Optionally, move the image back to its original location when viewport is 970px or larger
      $("#suggestions > img").appendTo("#combined_logos");
      $("#title").css("width",  "60%");
      $("#title").css("min-width",  "60%");
    }
  }
  
  // Call the function once when the document is ready
  moveImageBasedOnViewport();
  
  // Call the function every time the window is resized
  $(window).resize(moveImageBasedOnViewport);

});
$(document).on('ready	 page:load', function(){
	$('a#skip-nav-link').on('keydown', function(e){
		  var e = getEvent(e);
      var keyCode = getKeyCode(e);
      if (keyCode == 13) {
      	e.preventDefault();
      	$('#maincontent button:not([tabindex="-1"]), #maincontent a:not([tabindex="-1"])')[0].focus();
      };
	});
});
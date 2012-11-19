var getPageName = function(pathname) {
  if (pathname) {
    pathname = pathname.substring(pathname.lastIndexOf('/') + 1);
    if (pathname && pathname.indexOf('server_') === 0) {
      pathname = 'server.html';
    }
  }
  return pathname || 'index.html';
};


$(function(){

	// Select the appropriate tab by finding the li in the nav that corresponds to
	// this page and settings its class to 'active'.
	var pageName = getPageName(window.location.pathname);
	var selector = '.nav a[href$="' + pageName + '"]';
	$(selector).parent().addClass('active');


/* Uncomment the event below once the CORS checker is supported.
	$("#checkcors").click(function () {
		var targetSite = $("#targetsite").val();
		$("#result").show();
		$.ajax({
			url : targetSite,
			method : 'get',
			beforeSend : function (xhr) {
				$("#result").html("Trying to perform a cross-origin request to " + targetSite);
		    },
			complete : function(xhr) {
				var buffer =  "<a href='" + targetSite + "'> " + targetSite + "</a> ";
				if(xhr.status != 0) { // CORS-enabled site

					buffer += "is CORS-enabled. The server responded with a <strong>" + xhr.status.toString() + "</strong> HTTP status code";
					if(xhr.getAllResponseHeaders() != null) {
						buffer +=	" and the following response headers: <pre>" +
									xhr.getAllResponseHeaders() +
									"</pre>"; //getResponseHeader('Access-Control-Allow-Origin')
					}
					else {
						buffer += ".";
					}
				}
				else {
					buffer += "seems not yet to be CORS-enabled.";
				}
				$("#result").html(buffer);
			}
		});
	});
*/
});

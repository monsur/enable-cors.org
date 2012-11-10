$(function(){
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
});
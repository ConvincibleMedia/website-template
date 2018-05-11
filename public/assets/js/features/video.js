$('.video .player').click(function(ev){
	ev.preventDefault();

	var $this = $(this);

	var params = '';
	$.each($this.data(), function(i, e){
		if (i != 'id') { params = params + i + '=' + e + '&'; }
	});
	var id = $this.data('id');

	var iframe = document.createElement("iframe");
	var embed = "https://www.youtube.com/embed/" + id + "?" + params + "autoplay=1";
	iframe.setAttribute("src", embed);
	iframe.setAttribute("frameborder", "0");
	iframe.setAttribute("allowfullscreen", "allowfullscreen");

	$this.replaceWith(iframe);
});

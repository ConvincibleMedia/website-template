---
---

/* ASSET: assets/js/layouts/main.js */

{% include js/vendor/jquery/jquery-plugins.js %}
{% include js/helpers.js %}

//$(".table").overflown() {}

function em(measure) {
	return ($(measure).width() / parseFloat($("body").css("font-size")));
}
function wind() {
	$('#em').text(em(window));
}
$(window).resize(wind);
wind();

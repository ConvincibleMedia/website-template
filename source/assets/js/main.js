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

$('.cell, .cell-flex, .cell-auto').each(function(a, obj1) {
	cell = $(obj1);
	cell.find('p').each(function(b, obj2) {
		$(obj2).text(cell.attr('class'));
	});
});

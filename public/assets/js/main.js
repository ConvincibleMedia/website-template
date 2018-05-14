/* ASSET: assets/js/layouts/main.js */

/* VENDOR: _includes/js/vendor/jquery-plugins.js */

(function() {
    var method;
    var noop = function () {};
    var methods = [
        'assert', 'clear', 'count', 'debug', 'dir', 'dirxml', 'error',
        'exception', 'group', 'groupCollapsed', 'groupEnd', 'info', 'log',
        'markTimeline', 'profile', 'profileEnd', 'table', 'time', 'timeEnd',
        'timeline', 'timelineEnd', 'timeStamp', 'trace', 'warn'
    ];
    var length = methods.length;
    var console = (window.console = window.console || {});

    while (length--) {
        method = methods[length];

        // Only stub undefined methods.
        if (!console[method]) {
            console[method] = noop;
        }
    }
}());

/* INCLUDE: _includes/js/helpers.js */

$.fn.overflown = function() {
	var e = this[0];
	return e.scrollHeight > e.clientHeight || e.scrollWidth > e.clientWidth;
}


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

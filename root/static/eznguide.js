jQuery(document).ready(function($) {
	var zeropad = function(s, n) {
		s += "";
		while (s.length < n) {
			s = "0" + s;
		}
		return s;
	};

	$('time').each(function() {
		var dt = new Date( $(this).attr('datetime') );

		var days = [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" ];
		var months = [
			"Jan", "Feb", "Mar", "Apr", "May", "Jun",
			"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
		];

		$(this).attr('title', $(this).text());
		$(this).text(
			days[dt.getDay()] + ", " +

			zeropad(dt.getDate(), 2) + " " +
			months[dt.getMonth()]    + " " +
			dt.getFullYear()         + " " +

			zeropad(dt.getHours(), 2) + ":" +
			zeropad(dt.getMinutes(), 2) + ":" +
			zeropad(dt.getSeconds(), 2)
		);

	});

	$('a')
		.filter(function(i) {
			return !/^#/.test( $(this).attr('href') );
		})
		.attr({
			title: 'Open link in new tab',
			target: '_blank',
		});
});

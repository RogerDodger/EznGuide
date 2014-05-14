(function() {
	var zeropad = function(s, n) {
		s += "";
		while (s.length < n) {
			s = "0" + s;
		}
		return s;
	};

	var elements = document.querySelectorAll('time');
	for (var i = 0; i < elements.length; i++) {
		var e = elements[i];
		var dt = new Date(e.getAttribute('datetime'));

		var days = [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" ];
		var months = [
			"Jan", "Feb", "Mar", "Apr", "May", "Jun",
			"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
		];

		e.title = e.innerHTML;
		e.innerHTML =
			days[dt.getDay()] + ", " +

			zeropad(dt.getDate(), 2) + " " +
			months[dt.getMonth()]    + " " +
			dt.getFullYear()         + " " +

			zeropad(dt.getHours(), 2) + ":" +
			zeropad(dt.getMinutes(), 2) + ":" +
			zeropad(dt.getSeconds(), 2)
		;
	}
})();

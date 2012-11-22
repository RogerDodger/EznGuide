jQuery(document).ready(function($) {
	
	$('time').each(function() {
		var dt = new Date( $(this).attr('datetime') );
		
		var days = [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" ];
		var months = [ 
			"Jan", "Feb", "Mar", "Apr", "May", "Jun", 
			"Jul", "Aug", "Sep", "Oct", "Nov", "Dec" 
		];
		
		$(this).attr('title', $(this).text());
		$(this).text(
			sprintf( "%s, %02d %s %d %02d:%02d:%02d",
				days[dt.getDay()],
				dt.getDate(), months[dt.getMonth()], dt.getFullYear(),
				dt.getHours(), dt.getMinutes(), dt.getSeconds()
			)
		);
		
	});
	
	$('a')
		.filter(function() {
			return $(this).attr('href').matches(/^#/);
		})
		.attr({
			title: 'Open link in new tab',
			target: '_blank',
		});
});

Sunlight.highlightAll();
#!/usr/bin/env perl
use utf8;

use warnings;
use strict;
use 5.014;
use Task::EznGuide v2012.11.22;

use FindBin '$Bin';
use YAML;
use File::Find;
use File::Copy 'cp';
use File::stat;
use Digest::MD5::File 'file_md5_hex';
use Template;
use Template::Stash;
use DateTime;
use Text::Markdown;
use HTML::TreeBuilder;
use Archive::Zip;
use Getopt::Long;

my $zip = 1;
GetOptions( 'zip!' => \$zip );

sub simple_uri {
	my $str = join "-", @_;
	
	for ( $str ) {
		s/[^a-zA-Z0-9\-\x20]//g; # Remove all except English letters, 
		                         # Arabic numerals, hyphens, and spaces.
		s/^\s+|\s+$//g; #Trim
		s/[\s\-]+/-/g; #Collate spaces and hyphens into a single hyphen
	}
	
	return $str;
}

chdir($Bin);

my ($config) = YAML::LoadFile( "config.yml" ) 
	or die "Config file not found. Have you created it yet?";	
die "$config->{path} is not a directory" unless -d $config->{path};

my $builddir = "$config->{path}/EznGuide";

unless( -e "$builddir/favicon.ico" ) {
	say "create $builddir/favicon.ico";
	cp("$Bin/root/favicon.ico", "$builddir/favicon.ico");
}

# Move static files into the builddir
chdir('root/static');
find( 
	sub { 
		if(-d) {
			my $dir = "$builddir/" . $File::Find::name;
			unless( -d $dir ) {
				mkdir $dir;
				say "create $dir";
			}
		}
		else {
			my $fn = "$builddir/" . $File::Find::name;
			if( !-e $fn || file_md5_hex($fn) ne file_md5_hex($_) ) {
				say "unlink $fn" if -e $fn;
				say "create $fn";
				cp($_, $fn);
			}
		}
	},
	".",
);

my $stash = Template::Stash->new($config);
my $tt = Template->new({
	INCLUDE_PATH => "$Bin/root/src",
	STASH => $stash,
	FILTERS => {
		time => sub {
			my $dt = DateTime->from_epoch( epoch => shift );
			return sprintf '<time datetime="%sZ">%s</time>',
				$dt->iso8601,
				$dt->strftime( '%a, %d %b %Y, %H:%M:%S UTC' ),
		},
		version => sub {
			my $fn = shift;
			return sprintf '%s?v=%s', $fn, stat($fn)->mtime;
		},
		markdown => Text::Markdown->new->can('markdown'),
	}
});

#Process templates
chdir('../src');
my $content = '';
for my $fn ( glob "content/*" ) {
	say "processing $fn";
	$tt->process($fn, undef, \$content);
}
chdir('../static');

#Process headings
my $tree = HTML::TreeBuilder->new;
$tree->no_expand_entities(1);
$tree->parse($content);
$tree->eof;
my @headers;
for my $e ( $tree->find('h1', 'h2', 'h3', 'h4') ) {
	if( (my $index = index $content, $e->as_HTML ) >= 0 ) {
		substr($content, $index, 0 ) = sprintf
		  '<p class="backtop">'
			. '<a id="%s" href="#Contents">Back to top</a>'
		. '</p>' . "\n" 
		. '<div class="clearfix"></div>' . "\n",
		simple_uri $e->as_text;
		(my $level = $e->tag) =~ s/h//;
		push @headers, { 
			contents => $e->as_text, 
			level    => $level,
			href     => simple_uri( $e->as_text ),
		}; 
	}
}
$stash->set('headers', \@headers);

#Process footnotes
my @footnotes;
my $n = 0;

my $b = quotemeta( my $begin_tag = '[[' );
my $e = quotemeta( my $end_tag = ']]' );

# Remove leading whitespace from begin tags to make source nicer
$content =~ s/\s+(?=$b)//g;

# Stack containing the indexes of open tags
# Whenever a closing tag is encountered, this stack is popped and a slice is
# taken to get the contents of the footnote
my @stack;

# The current depth is tracked so that the footnotes can be ordered by depth
my $depth = 0;

my @tokens = split /($b|$e)/, $content;
for ( my $i = 0; $i <= $#tokens; $i++ ) 
{
	if( $tokens[$i] eq $begin_tag ) 
	{
		push @stack, $i;
		$depth++;
	}
	elsif( $tokens[$i] eq $end_tag && $depth >= 0 )
	{
		$depth--;
		$footnotes[$depth] //= [];
		push $footnotes[$depth], join '', @tokens[pop @stack .. $i];
	}
}

if( @footnotes ) {
	my $footref_fmt = '<sup><a id="foot-%s" href="#foot-%s">%d</a></sup>';
	$content .= '
	<h1>Footnotes</h1>
	<ul class="footnotes">
	';
	for my $footnote ( map { ref $_ ? @$_ : $_ } @footnotes ) 
	{
		$n++;
		
		#Replace content with numbered foot reference
		substr(
			$content, 
			index($content, $footnote), 
			length $footnote
		) = sprintf $footref_fmt, "$n-a", $n, $n;
		
		#Append note
		my $backref = sprintf $footref_fmt, $n, "$n-a", $n;
		s/^$b//, s/$e$// for $footnote; 
		$content .= "\t<li>$backref $footnote</li>\n";
	}
	$content .= "</ul>\n";
}

$stash->set('content', $content);

#Process wrapper
my $fn = "$builddir/index.html";
say "unlink $fn" if -e $fn;
say "create $fn";
$tt->process("wrapper.tt", undef, $fn);

if( $zip ) {
	#Compress site for ease of downloading
	my $az = Archive::Zip->new();
	$az->addTree($builddir, '', sub { !/\.zip$/ });
	$fn = "$builddir/site.zip";
	say "unlink $fn" if -e "$fn";
	say "create $fn";
	$az->writeToFileNamed("$fn");
}

__END__
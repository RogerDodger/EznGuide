#!/usr/bin/env perl
use utf8;
use 5.014;
use warnings;

use FindBin '$Bin';
use YAML;
use File::Find;
use File::Copy 'cp';
use File::stat;
use File::Spec::Functions;
use Digest::MD5::File 'file_md5_hex';
use Template;
use Template::Stash;
use DateTime;
use Text::Markdown;
use Text::Typography qw/typography/;
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

# Monkey patch new method to elements
#
# Output the tag contents, ignoring optional nested elements by element name
sub HTML::Element::guts {
	my($e, $opt) = @_;

	$opt->{ignore} //= [];

	return join "", map {
		if(ref $_) {
			# isa HTML::Element
			if($_->tag ~~ $opt->{ignore}) {
				# If ignoring, don't wrap with the tag
				$_->guts($opt);
			}
			else {
				# Otherwise, wrap guts in tag + attributes
				my %attr = $_->all_external_attr;
				sprintf "<%s%s>%s</%s>",
					$_->tag,
					( join "", map { " $_=\"$attr{$_}\"" } keys %attr ),
					$_->guts($opt),
					$_->tag;
			}
		}
		else {
			$_;
		}
	} $e->content_list;
}

chdir($Bin);

my ($config) = YAML::LoadFile( "config.yml" )
	or die "Config file not found. Have you created it yet?";
die "$config->{path} is not a directory" unless -d $config->{path};

my $builddir = $config->{path};

unless( -e (my $fn = catfile($builddir, "favicon.ico")) ) {
	say "create $fn";
	cp catfile($Bin, 'root', 'favicon.ico'), $fn;
}

# Move static files into the builddir
chdir( catdir('root', 'static') );
find(
	sub {
		if(-d) {
			my $dir = catdir($builddir, $File::Find::name);
			unless( -d $dir ) {
				mkdir $dir;
				say "create $dir";
			}
		}
		else {
			my $fn = catfile($builddir, $File::Find::name);
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
	INCLUDE_PATH => catfile($Bin, 'root', 'src'),
	STASH => $stash,
	FILTERS => {
		time => sub {
			my $dt = DateTime->from_epoch( epoch => shift );
			return sprintf '<time datetime="%sZ">%s</time>',
				$dt->iso8601,
				$dt->strftime( '%a, %d %b %Y %H:%M:%S UTC' ),
		},
		version => sub {
			my $fn = shift;
			return sprintf '%s?v=%s', $fn, stat($fn)->mtime;
		},
		markdown => sub {
			my $text = shift;

			$text = Text::Markdown->new->markdown($text);

			# Educate -- to en, and --- to em dashes
			$text = typography($text, 2);

			return $text;
		},
	}
});

#Process templates
chdir( catdir('..', 'src') );
my $content = '';
for my $fn ( glob catfile('content', '*') ) {
	say "processing $fn";
	$tt->process($fn, undef, \$content);
}
chdir( catdir('..', 'static') );

say "processing footnotes";
my @footnotes;

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

if( @footnotes = map { ref $_ ? @$_ : $_ } @footnotes )
{
	my $footref_fmt = '<sup><a id="foot-%s" href="#foot-%s">%d</a></sup>';
	$content .= '
	<h1>Footnotes</h1>
	<ul class="footnotes">
	';
	for(my $n = 1; $n <= @footnotes; $n++)
	{
		my $footnote = $footnotes[$n - 1];

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

say "processing tags";
$content =~ s`
	\[\#
	(.*?)
	(?{ $a = simple_uri(lc $^N) })
	\]
`<span class="tag $a">$1</span>`xg;

say "processing abbreviations";
my %abbr = (
	OC     => 'Original Character',
	EqD    => 'Equestria Daily',
	LUS    => 'Lavender Unicorn Syndrome',
	FiM    => 'Friendship is Magic',
	MLP    => 'My Little Pony',
	'Fo:E' => 'Fallout: Equestria',
);

while( my($abbr, $fullname) = each %abbr ) {
	$content =~ s`$abbr`<abbr title="$fullname">$abbr</abbr>`g;
}

say "processing headings";
my $tree = HTML::TreeBuilder->new;
$tree->no_expand_entities(1);
$tree->parse($content);
$tree->eof;

my @headers;
for my $e ( $tree->find('h1', 'h2', 'h3', 'h4') ) {
	if( (my $index = index $content, $e->as_HTML ) >= 0 ) {

		push @headers, {
			class    => $e->tag,
			href     => simple_uri( $e->as_text ),
			contents => $e->guts({ ignore => [ 'a' ] }),
		};

		#Prepend an anchor to the header
		substr($content, $index, 0 ) = sprintf
		  '<p class="backtop">'
			. '<a id="%s" href="#Contents">Back to top</a>'
		. '</p>' . "\n",
		$headers[-1]->{href};

	}
}
$stash->set('headers', \@headers);
$stash->set('content', $content);

#Process wrapper
my $fn = catfile($builddir, 'index.html');
say "unlink $fn" if -e $fn;
say "create $fn";
$tt->process("wrapper.tt", undef, $fn);

if( $zip ) {
	#Compress site for ease of downloading
	my $az = Archive::Zip->new();
	$az->addTree($builddir, '', sub { !/\.zip$/ });
	$fn = catfile($builddir, 'site.zip');
	say "unlink $fn" if -e "$fn";
	say "create $fn";
	$az->writeToFileNamed("$fn");
}

__END__

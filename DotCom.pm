package Chess::Games::DotCom;

use 5.006001;
use strict;
use warnings;

use Data::Dumper;
use HTML::TreeBuilder;
use LWP::Simple;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Chess::Games::DotCom ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	game_of_day
);

our $VERSION = '0.02';

our $home = 'http://www.chessgames.com';
my  $tb   = HTML::TreeBuilder->new;

# Preloaded methods go here.

my $ua;

sub _init_ua
{
    require LWP;
    require LWP::UserAgent;
    require HTTP::Status;
    require HTTP::Date;
    $ua = new LWP::UserAgent;  # we create a global UserAgent object
    my $ver = $LWP::VERSION = $LWP::VERSION;  # avoid warning
    $ua->agent("Mozilla/5.001 (windows; U; NT4.0; en-us) Gecko/25250101");
    $ua->env_proxy;
}

  
sub _get
{
    my $url = shift;
    my $ret;

    _init_ua() unless $ua;
    if (@_ && $url !~ /^\w+:/) 
      {
	  # non-absolute redirect from &_trivial_http_get
	  my($host, $port, $path) = @_;
	  require URI;
	  $url = URI->new_abs($url, "http://$host:$port$path");
      }
    my $request = HTTP::Request->new
      (GET => $url,
       
      );
    my $response = $ua->request($request);
    return $response->is_success ? $response->content : undef;
}


sub game_of_day {

    my $outfile = shift || "game_of_day.pgn";

    # retrieve http://www.chessgames.com

    my $html = get $home;

    # parse the page

    $tb->parse($html);

    my $god; # god == Game of the Day

    # make it so that text nodes are changed into nodes with tags
    # just like any other HTML aspect.
    # then they can be searched with look_down
    $tb->objectify_text;

    # Find the place in the HTML where Game of the Day is
    my $G = $tb->look_down
      (
       '_tag' => '~text',
       text   => 'Game of the Day'
      );

    # warn $G->as_HTML;

    # find _all_ tr in the lineage of the found node... I don't know a 
    # way to limit the search
    my @U = $G->look_up
      (
       '_tag' => 'tr',
      );

    # by inspecting the output of $tree->dump, I saw that certain parts of the
    # tree had certain absolute addresses from the root of the tree.
    # I had planned a neat API allowing one to access various aspects of the
    # Game of the Day, but for now, I just want the chessgame!
    my %address = 
      (
       'date' => '0.1.2.0.0.0.0.0.0.0.0.0.0.0.2.0',
       'game_url' => '0.1.2.0.0.0.0.0.0.0.0.1.0.0.0.1',
       'white_player' => '0.1.2.0.0.0.0.0.0.0.0.1.0.0.0.1.0',
       'black_player' => '0.1.2.0.0.0.0.0.0.0.0.1.0.0.0.1.4',
       'game_title'   => '0.1.2.0.0.0.0.0.0.0.0.1.0.0.0.3.0',
      );

    
    # debugging output
    while ( my ($k, $v) = each %address ) {
#	warn " ** $k ** ", $/, $tb->address($v)->as_HTML, $/ 
    }

    # lets get the URL of the game
    my $game_url  = $tb->address($address{game_url})->attr('href');
    my ($game_id) = $game_url =~ m/(\d+)/;

    # let's get the game, faking out the web spider filter in the process:
    my $pgn       = _get "http://www.chessgames.com/perl/nph-chesspgndownload?gid=$game_id";

    # let's save it to disk
    open F, ">$outfile" or die "error opening $outfile for writing: $!";
    print F $pgn;
    close(F)
    
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Chess::Games::DotCom - API for accessing chessgames.com

=head1 SYNOPSIS

  shell> perl -MChess::Games::DotCom -e  game_of_day
  shell> perl -MChess::Games::DotCom -e 'game_of_day("myfile.pgn")'

=head1 ABSTRACT

Download games from chessgames.com.

=head1 API

=head2 game_of_day [ $filename ]

Downloads the game of the day. If C<$filename> is not specified, then
it downloads it to C<game_of_day.pgn>.

=head2 EXPORT

C<game_of_day>


=head1 TODO

Download other daily game parts of the site

=head1 RESOURCES

The Perl Chess Mailing List:

  http://www.yahoogroups.com/group/perl-chess

=head1 AUTHOR

T. M. Brannon, <tbone@cpan.org>


=head1 INSTALLATION

You must have the following installed:

=over 4

=item 1 L<URI>

=item 2 L<Bundle::LWP>

=item 3 L<HTML::Tree>

=cut

I had serious problems using L<CPANPLUS> to install these, so you will 
probably have to install each manually before downloading and installing 
this.

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by T. M. Brannon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use Cwd qw(getcwd);
use Getopt::Long 'GetOptions';
use Pod::Usage 'pod2usage';

pod2usage(-verbose => 99, -sections => [qw(NAME)] ) if @ARGV < 1;
my $force_season = '';
GetOptions(
    'help'          => \my $help,
    'man'           => \my $man,
    "title=s"       => \my $title,
    "season=s"      => \$force_season,
);
pod2usage(-verbose => 99, -sections => [qw(SYNOPSIS)] ) if $help;
pod2usage(-verbose => 99, -sections => [qw(SYNOPSIS DESCRIPTION)] ) if $man;


my $path = getcwd();
opendir( my $DIR, $path );
while ( my $entry = readdir $DIR ) {
    next unless -d $path . '/' . $entry;
    next if $entry eq '.' or $entry eq '..';
    # print "Found directory $entry\n";

    chdir $entry;
    my @files = glob("*.avi *.divx *.mkv *.mp4 *.flv *.smi *.srt");

    for my $file (@files) {
        my $season  = '';
        my $episode = '';
        my $file_ext;
        if ($file =~/\.([^.]+)$/) {
            $file_ext = lc $1;
        } 
        #try to get season and episode
        #Check if using S<SS>E<EE> format
        if ($file =~/s(\d+).?e(\d+)/i) {
            $season  = sprintf "S%02d", $1;
            $episode = sprintf "E%02d", $2;
        #Check if using Season <SS> Episode <EE> format
        } elsif ($file =~/season *(\d+)/i) {
            $season  = sprintf "S%02d", $1;
            if ($file =~/episode *(\d+)/i) {
                $episode = sprintf "E%02d", $1;
            }
        #Check if using <SS>x<EE> format
        } elsif ($file =~/(\d+)x(\d+)/i) {
            $season  = sprintf "S%02d", $1;
            $episode = sprintf "E%02d", $2;
        
        #Check if using <S><EE> format 
        #Could mismatch to title containing numbers
        } elsif ($file=~/\D(\d)(\d\d)/) {
            $season  = sprintf "S%02d", $1;
            $episode = sprintf "E%02d", $2;
        }

        #If season could not be parsed check if forced_season variable is not empty
        if ($force_season ne '') {
            $season = sprintf "S%02d", $force_season;
            if ($file =~/episode *(\d+)/i) {
                $episode = sprintf "E%02d", $1;
            } elsif ($file =~/e(\d+)/i) {
                $episode = sprintf "E%02d", $1;
            }
        } 

        #if season and episode are both valid, proceed with renaming
        if ($season eq '' or $episode eq '') {
            say "Error getting season or episode: $file";
        } else {
            if ($file_ext =~ /srt|smi/) {
                rename $file, "$title $season$episode\.en\.$file_ext";
            } else {
                rename $file, "$title $season$episode\.$file_ext";
            }
        }
    }
    chdir $path;
}
closedir $DIR;

__END__

=head1 NAME

rename_tv.pl --title ["title"] --season [#]

=head1 SYNOPSIS

rename_tv.pl --title ["title"] --season [#]

    Options:
    -help            brief help message
    -title           title of the show
    -season          force season number

=head1 OPTIONS

=over 4

=item B<-help>

 Print a brief help message and exits.

=item B<-title>

 Title of the show. Must be enclosed with "" if it contains spaces.

=item B<-season>

 Season to use if not detected

=back

=head1 DESCRIPTION

B<This program> will read rename all video files in this format:
B<[title] S[NN]E[NN].[file_ext]>

=cut
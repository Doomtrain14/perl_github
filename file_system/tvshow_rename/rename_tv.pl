#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use Cwd qw(getcwd);

if (@ARGV < 1) {
    die "Usage:\n\ttvsreies_renamer.pl <title> <opt season>\n\n";
}
my $title = $ARGV[0] || "Default";
my $force_season = $ARGV[1] || '';

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
            rename $file, "$title $season$episode\.$file_ext";
        }
    }
    chdir $path;
}
closedir $DIR;
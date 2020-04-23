use strict;
use warnings;
use feature 'say';
use Getopt::Long 'GetOptions';
use Pod::Usage 'pod2usage';

my $datalog_file =  '';
my $log_level    =  1;

pod2usage(-verbose => 0) if @ARGV < 1;
GetOptions(
    'help'      => \my $help,
    'man'       => \my $man,
    "file=s"    => \$datalog_file,
    "log=i"     => \$log_level
);
pod2usage(-verbose => 1) if $help;
pod2usage(-verbose => 2) if $man;



if ($datalog_file eq '') {
    exit;
} else {
    if (not -e $datalog_file) {
        say "File not found : [$datalog_file]";
        exit;
    }
}

#Error Codes
use constant NO_ERROR                   => 0;
use constant ERR_HEADER_MISMATCH        => 1;
use constant ERR_COL_COUNT_MISMATCH     => 2;

my $FILE_INPUT;
open($FILE_INPUT,  '<', $datalog_file) or die "Could not open input file!\n";

my $line_ctr    =   1;
my $header_flag =  -1;


my @last_header             =  "";
my $last_header_colcount    =  0;
my %test_info;

my $die_x;
my $die_y;
while (<$FILE_INPUT>) {
    chomp;
    my $line = $_;
    if (/^ *#DIE_X +([^ ]+)/) {
        $die_x = $1;
    }
    if (/^ *#DIE_Y +([^ ]+)/) {
        $die_y = $1;
    }
    if (/^ *#START_HEADER/) {
        $header_flag = 1;
    }
    if (/^ *#END_HEADER/) {
        #check if start header was found
        if ($header_flag == 1) {
            $header_flag = 0;
        } else {
            printf ("Line %08d: #END_HEADER found before #START_HEADER\n",$line_ctr);
        }
    }
    unless (/^ *#/) {
        if (/^ *TNAME/) {
            @last_header    = $line=~/[^ ]+/g;
            $last_header_colcount     = @last_header;
        #Assumes other entry which does not have # 
        #is test data
        }else {
            my @test_data   = $line=~/[^ ]+/g;
            my $error_flag  = 0;
            #Assumes first entry is the test block
            my $testname    = $test_data[0];

            #if test already exists in hash, check if header match
            if (exists $test_info{$testname}) {
                if ($test_info{$testname}{header} ne "@last_header") {
                    if ($test_info {$testname}{err_code}{ERR_HEADER_MISMATCH}<1) {
                        if ($log_level > 0) {
                            printf ("Line % 10d: Column header mismatched (Test = %s, X = $die_x, Y = $die_y)\n",$line_ctr, $testname);
                        }
                        if ($log_level > 1) {
                            say   ((" " x 17)."@last_header");
                            say   ((" " x 17)."$test_info{$testname}{header}\n"); 
                        }
                    }
                    $test_info {$testname}{err_code}{ERR_HEADER_MISMATCH}++;
                }
            } else {
                #Check if last header col count matches data col count
                if ($last_header_colcount != @test_data) {
                    if ($log_level > 0) {
                        printf ("Line % 10d: Column count mismatch    (Test = %s, X = $die_x, Y = $die_y)\n",$line_ctr, $testname);
                    }
                    $test_info {$testname}{err_code}{ERR_COL_COUNT_MISMATCH}++;
                }

                $test_info {$testname} = {
                    header    => "@last_header",
                    col_count => $last_header_colcount,
                    err_code  => {
                        ERR_HEADER_MISMATCH     => 0,
                        ERR_COL_COUNT_MISMATCH  => 0
                    }
                }
                
            }

        }
    } 
    $line_ctr++;
}
close $FILE_INPUT;

my $total_error = 0;

my @error_data;
for my $test (sort keys %test_info) {
    my $err_count = 0;
    for my $err (sort keys %{$test_info{$test}{err_code}}) {
        $err_count += $test_info{$test}{err_code}{$err};
        
    }

    if ($err_count) {
        push @error_data, sprintf ("%-25s : %d", $test,$err_count);
    }
    $total_error += $err_count;
}

if ($total_error) {
    say "\nError breakdown per test:";
    for my $errors (@error_data) {
        say $errors;
    }
    printf ("%-25s : %d\n", "Total Error Count",$total_error);
} else {
    say "\nNo Error found\n";
}

__END__
=head1 NAME

logsum_check.pl [options] --file [file]

=head1 SYNOPSIS

logsum_check.pl [options] --file [file]

    Options:
    -help            brief help message
    -file            specify path of datalog file
    -log             log level 0 to 2

=head1 OPTIONS

=over 4

=item B<-help>

 Print a brief help message and exits.

=item B<-log>

 0 - Only the summary will be printed
 1 - Error and line number will be printed
 2 - Error details will be printed

=back

=head1 DESCRIPTION

B<This program> will read the input datalog file(s) and check if it violates the law of physics.

=cut

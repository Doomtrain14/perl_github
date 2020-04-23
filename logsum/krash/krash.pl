use strict;
use warnings;

if (@ARGV<2) {
    print "\nUsage:\n\n    krash.pl -a <file> <test_name>\n\n    -a Append to output file instead of overwrite\n\n";
    exit;
}

my $arg_str  = "@ARGV";
my $append   = int ($arg_str=~s/-a //);
my @args     = split / /,$arg_str;

my $filename = shift @args;
my $testname_list = join "|", @args;
my $regex = qr/($testname_list)/;
my %hash_buff;

if ($append == 0) {
    for my $test (@args) {
        unlink $test.'.csv';
    }
}

my $FILE_INPUT;
open($FILE_INPUT,  '<', $filename) or die "Could not open input file!\n";

my $testname            = "";
my $productname         = 'prodname';
my $programrev          = '99.99';
my $operatorlotname     = 'operlotname';

my $lotname             = '0C00000';
my $wafer               = '99';
my $temperature         = '99';

my $testsite;
my $x_coord;
my $y_coord;

my @testheader;
my @testdetails;
my %testcollookup = qw(TNAME 9 VCC 10 SUPPLIES 11 VALUE 13 INT 14 LOG_INT 14 RESULTS 15 PATTERN 16 STATE 17 CONDITION1 19 NUM 19 CONDITION2 20 CONDITION3 21 TEXT 21);

#Set separator  to comma
$"= ",";
my @main_buff;
while (<$FILE_INPUT>) {
    chomp;

    if (/^#PRODUCT +(\S+)/) {
        $productname = $1;
    }

    if (/^#REV +(\S+)/) {
        $programrev = $1;
    }

    if (/^#OPER_LOT_ID +(\S+)/) {
        $operatorlotname = $1;
    }

    if (/^#LOT +(\S+)/) {
        if (length $1 > 6) {
            $lotname = $1=~s/(.{7}).*/$1/r; #get first 7 char
        } else {
            $lotname = $1;       
        }
    }

    if (/^#WAFER +(\S+)/) {
        $wafer = $1;
    }

    if (/^#TEMP +(\S+)/) {
        $temperature = $1;
    }

    if (/^#START_DEVICE/) {
        @main_buff = ();
    }

    if (/^#DIE_X +(\S+)/) {
        $x_coord = $1;
    }

    if (/^#DIE_Y +(\S+)/) {
        $y_coord = $1;
    }

    if (/^#SITE +(\S+)/) {
        $testsite = $1;
    }
    if (/^TNAME/) {
        @testheader = /\S+/g;        
    }
    
    if (/^($regex) /) {
        $testname = $1;

        my @sub_buff = (" ") x 23;
        $sub_buff[0]  = $productname;
        $sub_buff[1]  = $programrev;
        $sub_buff[2]  = $operatorlotname;
        $sub_buff[3]  = $lotname;
        $sub_buff[4]  = $wafer;
        $sub_buff[5]  = $x_coord;
        $sub_buff[6]  = $y_coord;
        $sub_buff[7]  = $testsite;
        $sub_buff[8]  = $temperature;

        @testdetails = /\S+/g;
        
        #This is where re-mapping happens
        for my $i (0..$#testheader) {
            my $index;
            $index = $testcollookup{$testheader[$i]};

            if ($testheader[$i] eq 'RESULTS') {
                $sub_buff[$index] = int $testdetails[$i]=~/PASS/;
            } else {
                $sub_buff[$index] = $testdetails[$i];
            }
        }

        push @{$hash_buff{$testname}}, [@sub_buff]; 
    }

    if (/^bin_result \S+ (\S+) (\S+)/) {
        for my $test (keys %hash_buff) {
            for my $data (@{$hash_buff{$test}}) {
                @{$data}[22] = $2;
                @{$data}[23] = $1
            }
        }
    }
    if (/^#END_DEVICE/) {
        for my $test (keys %hash_buff) {
            my $FILE_OUTPUT;
            my $fileout  = $test.'.csv';

            #if for append, check if output file already has header
            my $has_header = 0;
            if ($append == 1) {
                if (open($FILE_OUTPUT, '<', $fileout)) {;

                    while (<$FILE_OUTPUT>) {
                        chomp;
                        if (/^productname.+programrev/) {
                            $has_header = 1;
                            last
                        }
                    }

                    close $FILE_OUTPUT;
                }
            }

            open($FILE_OUTPUT, '>>', $fileout) or die "Could not open output file!\n";
            

            if (!$has_header) {
                print $FILE_OUTPUT "productname,programrev,operatorlotname,lotname,wafer,x,y,testsite,temperature,testname,vcc,vccio,vccaux,testdoublevalue,testintvalue,testpass,pattern,state,intval,condition1,condition2,text,bin,binname\n";
                $has_header = 1;
            }
            for my $data (@{$hash_buff{$test}}) {
                print $FILE_OUTPUT "@{$data}\n";
            }
            delete $hash_buff{$test};
            close $FILE_OUTPUT;
        }
    }
    
}

close $FILE_INPUT;


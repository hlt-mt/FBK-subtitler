#!/usr/bin/perl

exit print "usage: \n\n cat file.srt | $0 file.txt\n\n" if $#ARGV!=0;

# file.srt: srt file
# file.txt: text file

$err_msg = "\tErrore nell'apertura del file\n";
$|=1;
$n=0;

$txtfn=$ARGV[0];
open(FH, "<$txtfn") || die $err_msg;
chop(@txt=<FH>);
close(FH);

$n=0;
while ($in=<STDIN>) {
    chop($in);
    if ($in=~/^[ \t]*([0-9:,]+)[ \t]*-->[ \t]*([0-9:,]+)[ \t]*$/) {
        printf "%s\n", $in;
        while ($txt=<STDIN>) {
          chop($txt);
          if ($txt=~/^[ \t]*$/) {
                printf "\n";
                last;
          } else {
                printf "%s\n", $txt[$n++];
          }
        }
    } else {
            printf "%s\n", $in;
    }
}

exit(0);


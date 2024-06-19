#!/usr/bin/perl

exit print "ARGS: txtFile durFile alignedFile\n" if $#ARGV < 2;


$|=1;

$txtF = $ARGV[0];
$durF = $ARGV[1];
$aliF = $ARGV[2];

open(FINTXT, "$txtF") || die "cannot open $txtF\n";
chop(@txt=<FINTXT>);
close(FINTXT);

open(FINDUR, "$durF") || die "cannot open $durF\n";
chop(@dur=<FINDUR>);
close(FINDUR);

open(FINALI, "$aliF") || die "cannot open $aliF\n";
chop(@ali=<FINALI>);
close(FINALI);


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


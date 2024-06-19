#!/usr/bin/perl

exit print "usage: \n\n $0 src.srt trg.txt\n\n" if $#ARGV!=1;

# src.srt: srt file with N blocks
# trg.txt: text file with N lines
# stdou: srt file where original text is replaced by the trg.txt content

$err_msg = "\tError in opening file\n";
$|=1;

$fn=$ARGV[0];
open(FH, "<$fn") || die $err_msg;
chop(@srt=<FH>);
close(FH);

$fn=$ARGV[1];
open(FH, "<$fn") || die $err_msg;
chop(@trg=<FH>);
close(FH);
$trgIdx=0;

for ($i=0; $i<=$#srt; $i++) {
  	if ($srt[$i]=~/^[ \t]*([0-9:,]+)[ \t]*-->[ \t]*([0-9:,]+)[ \t]*$/) {
		printf "%d\n%s\n", $trgIdx+1, $srt[$i];  # print index and timestamps of the current source block
		while ($i<=$#srt) {	                 # read all the lines of the current source block (see "last" below -> stopping)
			$src=$srt[++$i];
          		chop($src);
          		if ($src=~/^[ \t]*$/) {		 # no more lines of the current source block: print the single target line
                		printf "%s\n\n", $trg[$trgIdx++];
                		last;
          		}
        	}
  	}     

}

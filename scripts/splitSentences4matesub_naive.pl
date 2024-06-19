#!/usr/bin/perl -w

use utf8;
use Encode;

# Based on Preprocessor written by Philipp Koehn

#binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

use FindBin qw($Bin);
use strict;

my $mydir = "$Bin/nonbreaking_prefixes";

my %NONBREAKING_PREFIX = ();
my $QUIET = 0;
my $HELP = 0;
my $maxLineLen = 42;
my $maxLinesInBlock = 2;
my $verbose = 0;
my $endPunctPenalty = 15;
my $tagType = "DNT";

while (@ARGV) {
	$_ = shift;
	/^-c$/ && ($maxLineLen = shift, next);
	/^-b$/ && ($maxLinesInBlock = shift, next);
        /^-t/ &&  ($tagType = shift, next);
	/^-q$/ && ($QUIET = 1, next);
	/^-h/  && ($HELP = 1, next);
	/^-v/ &&  ($verbose = 1, next);
}

if ($HELP) {
    print "Usage 
   cat <textfile> | perl split-sentences.perl
                    (-h : print this message)
                    (-v : verbose output)
                    (-c maxLineLen [default: 42 (chars)]) 
                    (-b maxLinesInBlocks [default: 2])
		    (-t tagType (DNT or CHR) [default: DNT]\n";
	exit;
}

##loop text
my $text = "";
while(my $in = <STDIN>) {
    $in = decode('UTF-8', $in);
    if ($in=~/^([ \t]*|[0-9]+)$|\-\-\>/) {
	printf "%s", $in;
    } else {
	chop($in);
	printf "%s\n", &preprocess($in);
    }
}

sub preprocess {
	#this is one paragraph
        my($text) = @_;
    
	# clean up spaces at head and tail of each line as well as any double-spacing
	$text =~ s/[\xc2\xa0]+/ /g; # \xc2\xa0 (non break space)
	$text =~ s/​+/ /g;   # \xe2\x80\x8b (zero width space)

	$text =~ s/[\pZ\pC]+/ /g; 	# NEW Sept 2022 - FBK: split on more generic set of spaces

	$text =~ s/ +/ /g;
	$text =~ s/^ //g;
	$text =~ s/ $//g;

	return "" if !$text || $text eq " ";
	return "$text" if (length($text)<=$maxLineLen || $maxLinesInBlock==1);

	my @hyps=&generateHyps($maxLinesInBlock, $text);
	my %hypScore=&scoreHyps($maxLineLen, @hyps);

	printf "best hyp = <%s> [score=%f]\n", &findBest(%hypScore), $hypScore{&findBest(%hypScore)} if ($verbose);
	
	return &findBest(%hypScore);
}

sub findBest() {
    my (%hypScore) = @_;
    my $bestH = "";
    my $bestS = 999999;

    foreach my $hyp (keys %{hypScore}) {
	if ($hypScore{"$hyp"}<$bestS) {
	    $bestS=$hypScore{"$hyp"};
	    $bestH=$hyp;
	}
    }
    return $bestH;

}

sub scoreHyps () {
    my ($maxLen, @hyps) = @_;
    my (%scores)=();
    my ($score, $hypLen, $avgLen, @line);
    
    for (my $i=0; $i<=$#hyps; $i++) {
	printf "hyp[%d]=<%s>\n", $i, $hyps[$i] if ($verbose);

	# score the length of each line vs. maxLen:
	
	if ($tagType eq "CHR") {
		@line=split(/ Ԋ /, $hyps[$i]);
	} else {
		@line=split(/ \$\{DNT1\} /, $hyps[$i]);
	}
	$score = 0;
	$avgLen=0.0;
	for (my $j=0; $j<=$#line; $j++) {
	    $hypLen = length($line[$j]);
	    $avgLen+=$hypLen;
	    $score+=($hypLen>$maxLen)?$hypLen-$maxLen:0;
	    printf "line[%d]=<%s> len=%d sc=%d\n", $j, $line[$j], $hypLen, $score if ($verbose);
	}

	# score the variance across lines
	$avgLen/=($#line+1);
	printf "avgLen=%f\n", $avgLen if ($verbose);
	for (my $j=0; $j<=$#line; $j++) {
	    $hypLen= length($line[$j]);
	    printf "var(%d) =  %f\n", $hypLen, abs($hypLen-$avgLen) if ($verbose);
	    $score+=abs($hypLen-$avgLen);
	    printf "line[%d]=<%s> sc=%d\n", $j, $line[$j], $score if ($verbose);
	}
	
	# score the presence/absence of punctuation marks at the end of lines
	for (my $j=0; $j<$#line; $j++) {
	    if (!($line[$j]=~/[[:punct:]]$/)) {
		$score+=$endPunctPenalty;
	    }
	}
	$scores{$hyps[$i]}=$score; 

	printf ">>> score = %f hyp=%s\n", $score, $hyps[$i] if ($verbose);
	
    }

    return %scores;
}


sub generateHyps () {
    my ($N, $block) = @_;
    my ($hyp, $hypSuffix);

    my @hyps=();
    my @tmp=split(/ /, $block);

    # Generate hyps with 1 single EOL (2 lines)
    for (my $i=0; $i<$#tmp; $i++) {
	$hyp=join(" ", @tmp[0..$i]);

	if ($tagType eq "CHR") {
                $hyp .= " Ԋ ";
        } else {
                $hyp .= " \${DNT1} ";
        }

	$hyp .= join(" ", @tmp[$i+1..$#tmp]);
	printf "1EOL: %s\n", $hyp if ($verbose);;
	push @hyps, $hyp;
    }

    $hyp="";

    if ($N>2) {
	# Generate hyps with 2 EOLs (3 lines); N>2 not handled!
	for (my $i=0; $i<$#tmp; $i++) {
	    $hyp=join(" ", @tmp[0..$i]);
	    if ($tagType eq "CHR") {
              	$hyp .= " Ԋ ";
	    } else {	
                $hyp .= " \${DNT1} ";
            }
	    for (my $j=$i+1; $j<$#tmp; $j++) {
		$hypSuffix = join(" ", @tmp[$i+1..$j]);
		if ($tagType eq "CHR") {
                	$hypSuffix .= " Ԋ ";
                } else {
                	$hypSuffix .= " \${DNT1} ";
            	}
		$hypSuffix .= join(" ", @tmp[$j+1..$#tmp]);

		printf "2EOL: %s\n", "$hyp $hypSuffix" if ($verbose);
	
		push @hyps, "$hyp $hypSuffix";
	    }
	}
    }
    return @hyps;
}

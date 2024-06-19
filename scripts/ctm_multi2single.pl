#!/usr/bin/perl

# input format:
#   srcID   channel startSec durSec token confidence tokenType spk
#   talkid1 1       0.000    0.418  hello 1.000000   lex       unknown
#

use strict;

$|=1;

my(@input);
while (<STDIN>) {
    chop;
    push @input, $_;
}

my($globalId, $globalCh) = ("id", 1);

my($globalDeltaS, $lastDeltaS, $lastId, $cnt, $globalStartS);
my($in, $id, $ch, $startS, $durS, @rest);

$globalDeltaS = 0;
$lastDeltaS   = 0;
$lastId       = "";
$cnt = 0;
foreach $in ( @input ) {
    $cnt++;
    ($id, $ch, $startS, $durS, @rest) = split('\s+', $in);
    if ($lastId ne "") {
	if ($id ne $lastId) {
	    $globalDeltaS += $lastDeltaS;
	    ## printf("  change $id at %d ($globalDeltaS)\n", $cnt);
	} else {
	    $lastDeltaS = $startS + $durS;
	}
    }
    $globalStartS = $globalDeltaS + $startS;
    printf("%s %s %.3f %.3f %s\n", $globalId, $globalCh, $globalStartS, $durS, "@rest");
    $lastId = $id;
}


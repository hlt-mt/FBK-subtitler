#! /usr/bin/env perl

# ----

use strict;

my $line;
my $cnt = 0;
my $inBlockFlag = 0;
my $prevBlockId = 0;
my $currBlockId;
my $timeInfo;
my $content = "";
my $prevEndSec = -1;


sub checkContent {
    my($txt) = @_;
    if ($txt =~ /^Sottotitoli (creati|a cura)/) {
	return 0;
    }
    return 1;
}

sub getTsString {
    my($seconds) = @_;
    my $h = int($seconds / 3600);
    my $m = int(($seconds - $h * 3600) / 60);
    my $s = $seconds - $h * 3600 - $m * 60;
    ## printf STDOUT "      $h   $m  $s\n";
    return sprintf "%02d:%02d:%02.3f", $h, $m, $s;
}

while (<STDIN>) {
    chop;
    $line = $_;
    $cnt++;

    if (! $inBlockFlag) {
	if ($line =~ /^(\d+)$/) {
	    $currBlockId = $1;
	    $inBlockFlag = 1;
	    next;
	}
	printf STDERR "STRANGE STATE at $cnt\n";
	next;
    }

    # $inBlockFlag == 1
    #   00:01:29,890 --> 00:01:34,890
    if ($line =~ /^\s*(\d+):(\d+):(\d+),(\d+)\s+-->\s+(\d+):(\d+):(\d+),(\d+)\s*$/) {
	$timeInfo = $line;
        my ($sh,$sm,$ss,$su,$eh,$em,$es,$eu) = ($1,$2,$3,$4,$5,$6,$7,$8);
	my $startSec = $sh * 3600 + $sm * 60 + $ss + $su / 1000; 
       	my $endSec = $eh * 3600 + $em * 60 + $es + $eu / 1000;
	if ($startSec < $prevEndSec) {
	    my $tsA = getTsString($startSec);
	    my $tsB = getTsString($prevEndSec);
	    print STDOUT "ERROR: (line $cnt, block $currBlockId): $tsA < $tsB ($startSec < $prevEndSec)\n";
	}
	$prevEndSec = $endSec;
	next;
    }
    if ($line =~ /^\s*$/) {
	$currBlockId = $prevBlockId + 1;
       	$prevBlockId = $currBlockId;
	$inBlockFlag = 0;
	$content = "";
	next;
    }
    $content .= "$line\n";
    next;
}



#! /usr/bin/env perl

# ----
# delete blocks if containing only non appropriate sentences
# ----

use strict;

my $line;
my $cnt = 0;
my $inBlockFlag = 0;
my $prevBlockId = 0;
my $currBlockId;
my $timeInfo;
my $content = "";


sub checkContent {
    my($txt) = @_;
    if ($txt =~ /^Sottotitoli (creati|a cura)/) {
	return 0;
    }
    return 1;
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
    if ($line =~ /^\s*([\d\,\:]+) --> ([\d\,\:]+)\s*$/) {
	$timeInfo = $line;
	next;
    }
    if ($line =~ /^\s*$/) {
	if (checkContent($content)) {
	    $currBlockId = $prevBlockId + 1;
	    $prevBlockId = $currBlockId;
	    print STDOUT $currBlockId . "\n" . $timeInfo . "\n" . $content . "\n";
	}
	$inBlockFlag = 0;
	$content = "";
	next;
    }
    $content .= "$line\n";
    next;
}



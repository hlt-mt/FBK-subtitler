#!/usr/bin/perl

# input format:
#   srcID   channel startSec durSec token confidence tokenType spk
#   talkid1 1       0.000    0.418  hello 1.000000   lex       unknown
# output format:
#   1
#   00:09:57,720 --> 00:10:01,640
#   hello bla bla bla ...
#

use strict;

$|=1;

sub sec2str {
    my($sec) = @_;
    my $h = int($sec / 3600);
    my $m = int(($sec - $h * 3600) / 60);
    my $s = int($sec - $h * 3600 - $m * 60);
    my $us = int(($sec - $h * 3600 - $m * 60 - $s) * 1000);
    return sprintf("%02d:%02d:%02d,%03d", $h, $m, $s, $us);
}


my(@input);
while (<STDIN>) {
    chop;
    push @input, $_;
}

my($lastId, $cnt);
my($in, $id, $ch, $startS, $durS, $token, @rest);
my($segStartS, $segEndS, @wList, $ts1, $ts2);

$lastId    = "";
@wList     = ();
$cnt = 0;
foreach $in ( @input ) {
    ($id, $ch, $startS, $durS, $token, @rest) = split('\s+', $in);
    if ($lastId eq "") {
	$cnt++;
	$segStartS = $startS;
	$segEndS   = $startS + $durS;
    } else {
	if ($id eq $lastId) {
	    push @wList, $token;
	    $segEndS = $segStartS + $startS + $durS;
	} else {
	    # print last segment
	    $ts1 = sec2str($segStartS);
	    $ts2 = sec2str($segEndS);
	    printf("$cnt\n$ts1 --> $ts2\n" . "@wList" . "\n\n");
	    # update variables
	    $cnt++;
	    $segStartS = $segEndS;
	    $segEndS = $segStartS + $startS + $durS;
	    @wList = ($token);
	}
    }
    $lastId = $id;
}
# print last segment
$ts1 = sec2str($segStartS);
$ts2 = sec2str($segEndS);
printf("$cnt\n$ts1 --> $ts2\n" . "@wList" . "\n\n");


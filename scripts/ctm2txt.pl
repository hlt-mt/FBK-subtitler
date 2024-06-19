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

my($lastId, $cnt);
my($in, $id, $ch, $startS, $durS, $token, @rest);

$lastId       = "";
$cnt = 0;
foreach $in ( @input ) {
    $cnt++;
    ($id, $ch, $startS, $durS, $token, @rest) = split('\s+', $in);
    if (($lastId ne "") && ($id ne $lastId)) {
      printf("\n%s ", $token);
    } else {
      printf("%s ", $token);
    }
    $lastId = $id;
}
printf("\n");


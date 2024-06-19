#! /usr/bin/env perl

# Usage:
#   cat <file>.ctm | egrep -v '^[ \t]*$'| perl ctm2srt.pl

sub myRound {
  my ($float) = @_;
  sprintf "%.0f", $float;
}


my($sT, $eT, $h1, $h2, $m1, $m2, $s1, $s2);
while (<STDIN>) {
    chop;
    $line = $_;
    # wrong format:
    #   0.00 --> 4.00
    #   1187.42 --> 1192.31
    # correct format:
    #   00:00:00,000 --> 00:00:04,000
    #   00:19:47,420 --> 00:19:52,310
    #
    if ($line =~ /^\s*([\d\.]+) --> ([\d\.]+)\s*$/) {
       $sT = $1;
       $eT = $2;
       $h1 = int($sT / 3600);
       $m1 = int(($sT - $h1 * 3600) / 60);
       $s1 = int($sT - $h1 * 3600 - $m1 * 60);
       $u1 = myRound(($sT - $h1 * 3600 - $m1 * 60 - $s1 ) * 1000);
       $h2 = int($eT / 3600);
       $m2 = int(($eT - $h2 * 3600) / 60);
       $s2 = int($eT - $h2 * 3600 - $m2 * 60);
       $u2 = myRound(($eT - $h2 * 3600 - $m2 * 60 - $s2 ) * 1000);
       printf STDOUT "%02d:%02d:%02d,%03d --> %02d:%02d:%02d,%03d\n", $h1, $m1, $s1, $u1, $h2, $m2, $s2, $u2;
    } else {
       printf STDOUT "%s\n", $line;
    }
}



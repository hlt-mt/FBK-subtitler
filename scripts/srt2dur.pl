#!/usr/bin/perl

$|=1;

while ($in=<STDIN>) {
  chop($in);
  #   00:01:29,890 --> 00:01:34,890
  if ($in=~/^\s*(\d+):(\d+):(\d+),(\d+)\s+-->\s+(\d+):(\d+):(\d+),(\d+)\s*$/) {
	$sh = $1;
	$sm = $2;
	$ss = $3;
	$su = $4;
	$eh = $5;
	$em = $6;
	$es = $7;
	$eu = $8;
	$startSec = $sh * 3600 + $sm * 60 + $ss + $su / 1000;
	$endSec = $eh * 3600 + $em * 60 + $es + $eu / 1000;
	printf "%.2f\n", ($endSec - $startSec);
  }	
}

exit(0);

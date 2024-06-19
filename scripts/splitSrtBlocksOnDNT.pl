#!/usr/bin/perl

# This scripts splits lines in SRT file read from stdin
# on DNT tags

$maxtwolines=1;

while ($in=<STDIN>) {
	if ($in=~/^([ \t]*|[0-9]+)$|\-\-\>/) {
		printf "%s", $in;
	} else {
		chop($in); $in=~s/[ \t]+/ /g; $in=~s/^ | $//g;
		$in=~s/^[ \t]*\$\{DNT[01]\}//;
                $in=~s/[ \t]*\$\{DNT[01]\}[ \t]*$//;
		if ($maxtwolines) {
                	$in=~s/[ \t]*\$\{DNT[01]\}[ \t]*/\n/;
			$in=~s/[ \t]*\$\{DNT[01]\}[ \t]*/ /g;
		} else {
			$in=~s/[ \t]*\$\{DNT[01]\}[ \t]*/\n/g;
		}
		printf "$in\n";
	}
}


#!/usr/bin/perl

$|=1;

while ($in=<STDIN>) {
  chop($in);
  if ($in=~/^[ \t]*([0-9:,.]+)[ \t]*-->[ \t]*([0-9:,.]+)[ \t]*$/) {
	while ($txt=<STDIN>) {
	  chop($txt);
	  if ($txt=~/^[ \t]*$/) {
		printf "\n";
		last;
	  } else {
		printf "%s ", $txt;
 	  }

	}
  }	
}

exit(0);

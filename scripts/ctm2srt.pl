#!/usr/bin/perl


# Usage:
#   cat <file>.ctm | egrep -v '^[ \t]*$'| perl ctm2srt.pl

while (<STDIN>) {
    chop;
    push @input, $_;
}

for ($l=0; $l<=$#input; $l++) {

    printf "%d\n", $l+1;
    $in=$input[$l];
    $in=~s/\|.* ([0-9\.None]+ [FalseTru]+)[ \t]*$/ $1/;
    $in=~s/^[ \t]+|[ \t]+$//g;
    @in=split(/[ \t]+/, $in);
    $start=$in[0];
    $duration=$in[1];
    $duration=0.01 if ($duration==0);
    $end=$start+$duration;
    $word=$in[2]; 
    ($hh,$mm,$sss,$dds)=&time2tags($start);
    printf("%02d:%02d:%s,%s --> ", $hh, $mm, $sss, $dds);
    ($hh,$mm,$sss,$dds)=&time2tags($end);
    printf("%02d:%02d:%s,%s\n", $hh, $mm, $sss, $dds);
    printf("%s\n\n", $word);
}

sub time2tags {
    my ($t) = @_;

    my $hh=int($t/3600);
    my $mmss=$t-3600*$hh;
    my $mm=int($mmss/60);
    my $ss=$mmss-60*$mm;
    my $sss=sprintf("%02d", int($ss));
    my $dds=sprintf("%.3f", $ss-(int($ss)));
    $dds=~s/^0\.//;
    return($hh,$mm,$sss,$dds)
}

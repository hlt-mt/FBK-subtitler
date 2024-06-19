#!/usr/bin/perl

# The script removes hallucinations from input text. 
# Hallucinations can be either "horizontal", that is within lines,
# or "vertical", that is involving consecutively repeated rows.
# In the first case, from each input line, consecutive single 
# tokens repeated for at least <hthresh> number of times
# are collapsed to 1:
# Examples: 
# echo "a a b c c c" | perl rmAllucinations.pl --hthresh 3 
# 	a a b c
# echo "a a b c c c" | perl rmAllucinations.pl --hthresh 2
# 	a b c
# In the second case, consecutive lines repeated for at least 
# <vthresh> number of times are collapsed to 1:
# (echo "a b"; echo "a b"; echo "c") | perl rmAllucinations.pl --vthresh 2
#	a b
#	c



use Getopt::Long "GetOptions";

my $type="txt";
my $hthr=4;
my $vthr=2;
my ($help, $i)=();


&GetOptions(
        'inType=s'  => \$type,
        'threshH=i' => \$hthr,
        'threshV=i' => \$vthr,
        'help' => \$help);


if ($help || (($type cmp "txt") && ($type cmp "srt")) || $vthr<0 ) {
        print "\nrmHallucinations.pl\n",
        "\t--inType  <string>     srt, txt             [optional; default: \"txt\"]\n",
        "\t--threshH <integer>    horizontal threshold [optional; default: 4; 0 for no removal]\n",
        "\t--threshV <integer>    vertical threshold   [optional; default: 2; 0 for no removal]\n",
        "\t--help                 print this screen\n\n";
        exit(1);

}

$vthr=99999 if ($vthr==0);


$verbose=0;

$|=1;

$prevSentence="__XYZ__";
$countV=0;
$subN=-1;
$firstBlock=1;

if (!($type cmp "txt")) { 
    while ($in=<STDIN>) { 
	chop($in); 
	$currSentence=$in; $currSentence=~s/[ \t]+/ /g; $currSentence=~s/^ | $//g; 
	printf ("cv=$countV ps=<$prevSentence> cs=<$currSentence>\n") if ($verbose); 
	if (!($currSentence cmp $prevSentence)) { 
	    $countV++; 
	} else {
	    # la frase corrente e` diversa da quella memorizzata.
	    # Quindi stampo la precedente secondo questo schema: 
	    #  se e` occorsa meno volte della soglia verticale -> tutte le sue occorrenze, 
	    #  altrimenti -> una sola volta
	    $ub=($countV>=$vthr)?1:$countV;
	    printf("stampa pv %d volte\n", $ub) if ($verbose);
	    for (my $i=1; $i<=$ub; $i++) {
		if ($hthr>0) {
		    printf("ori: %s\n\tcln: ", $prevSentence) if ($verbose);
		    printf("%s\n", &rmHHallucination($hthr, $prevSentence));
		} else {
		    printf("%s\n", $prevSentence);
		}
	    }
	    $prevSentence=$currSentence;
	    $countV=1;
	}
    }
}

if (!($type cmp "srt")) {
    %blocks = &readSrt(); # create hash $blocks{} and arrays $subtitles[] and $idxMap[]
    &printBlocks(%blocks) if ($verbose);

    for (my $n=0; $n<=$#idxMap; $n++) {
	$idx=$idxMap[$n];
	printf("Processing block n. %d (idx=%d):\n%s\nsubtitle: %s\n\n", $n, $idx, join("\n", @{$blocks{$n}}), $subtitles[$n]) if ($verbose);
	$currSentence = $subtitles[$n];
	printf("cs=<%s> ps=<%s>\n", $currSentence, $prevSentence) if ($verbose);
	if (!($prevSentence cmp "__XYZ__")) {
	    # sto lavorando sul primo blocco:
	    $prevSentence=$currSentence;
	    $countV = 1;
	    printf ("First block: countV=%d\n", $countV) if ($verbose);
	} elsif (!($currSentence cmp $prevSentence)) {
	    # potenziale allucinazione a livello di blocco:
	    $countV++;
	    printf ("Potential hall: countV=%d\n", $countV) if ($verbose);
	} else {
	    # il testo del blocco corrente e` diverso da quello memorizzato.
	    # Quindi stampo i blocchi precedenti che hanno tutti
	    # lo stesso testo, ovvero a partire da quello dove e` cominciata
	    # l'allucinazione: se ce ne sono meno della soglia 
	    # verticale, li stampo tutti, altrimenti solo il primo
	    printf("BLOCCO DIVERSO: countV=$countV vs $vthr=vthr\n") if ($verbose);
	    if ($countV<$vthr) {
		for ($i=$n-$countV; $i<$n; $i++) {
		    printf("Stampo block n. %d (idx=%d):\n%s\nsubtitle: %s\n\n", $i, $idxMap[$i], join("\n", @{$blocks{$i}}), $subtitles[$i]) if ($verbose);
		    printBlock($hthr, $idxMap[$i], @{$blocks{$i}});
		}
	    } else {
		printf("Stampo solo block n. %d (idx=%d):\n%s\nsubtitle: %s\n\n", $n-$countV, $idxMap[$n-$countV], join("\n", @{$blocks{$n-$countV}}), $subtitles[$n-$countV]) if ($verbose);
		    printBlock($hthr, $idxMap[$n-$countV], @{$blocks{$n-$countV}});
	    }

	    printf("RESET\n") if ($verbose);
	    $prevSentence=$currSentence;
	    $countV=1;
	}
    }
    
}

# Last sentence:

if (!($type cmp "txt")) {
    printf("Last sentence: countV=$countV vs $vthr=vthr\n") if ($verbose);
    $ub=($countV>=$vthr)?1:$countV;
    printf("stampa pv %d volte\n", $ub) if ($verbose);
    for (my $i=1; $i<=$ub; $i++) {
	if ($hthr>0) {
	    printf("ori: %s\n\tcln: ", $prevSentence) if ($verbose);
	    printf("%s\n", &rmHHallucination($hthr, $prevSentence));
	} else {
	    printf("%s\n", $prevSentence);
	}
    }
}

if (!($type cmp "srt")) {
    printf("Last block: countV=$countV vs $vthr=vthr\n") if ($verbose);
    printf("Last block is the n. %d (idx=%d):\n\n", $#idxMap, $idxMap[$#idxMap]) if ($verbose);

    if (!($currSentence cmp $prevSentence)) {
	# testo dell'ultimo blocco e` uguale a quello dei precedenti:
	if ($countV<$vthr) {
	    for ($i=$#idxMap+1-$countV; $i<=$#idxMap; $i++) {
		printf("Stampo block n. %d (idx=%d):\n%s\nsubtitle: %s\n\n", $i, $idxMap[$i], join("\n", @{$blocks{$i}}), $subtitles[$i]) if ($verbose);
		printBlock($hthr, $idxMap[$i], @{$blocks{$i}});
	    }
	} else {
	    printf("Stampo solo block n. %d (idx=%d):\n%s\nsubtitle: %s\n\n", $#idxMap+1-$countV, $idxMap[$#idxMap+1-$countV], join("\n", @{$blocks{$#idxMap+1-$countV}}), $subtitles[$#idxMap+1-$countV]) if ($verbose);
	    printBlock($hthr, $idxMap[$#idxMap+1-$countV], @{$blocks{$#idxMap+1-$countV}});
	} 
    } else {
	# il testo dell'ultimo blocco  e` diverso da quello memorizzato,
	# Quindi lo stampo
	printf("ULTIMO BLOCCO DIVERSO:") if ($verbose);
	printf("Stampo solo block n. %d (idx=%d):\n%s\nsubtitle: %s\n\n", $#idxMap, $idxMap[$#idxMap], join("\n", @{$blocks{$#idxMap}}), $subtitles[$#idxMap]) if ($verbose);
	printBlock($hthr, $idxMap[$#idxMap], @{$blocks{$#idxMap}});
    }
}

exit(0);

#
### Subroutines:
#

sub readSrt() {
    my (%blocks);
    my ($currLine, $in, $n);
    my ($idx) = -1;
    $n=0;

    while ($in=<STDIN>) {
	chop($in);
	$currLine=$in; $currLine=~s/[ \t]+/ /g; $currLine=~s/^ | $//g;

	if ($currLine) { # salto righe vuote
	    if ($currLine=~/^[0-9]+$/) { # inizio primo blocco
		if ($idx!=-1) {
			push(@{ $blocks{"$n"} }, "__EOB__");
			$n++;
		}
		$idx=$currLine;
		$idxMap[$n]=$idx;
	    } else { 
		push(@{ $blocks{"$n"} }, $currLine);
		if (!($currLine=~/^[ \t]*([0-9:,.]+)[ \t]*-->[ \t]*([0-9:,.]+)[ \t]*$/)) {
		    $subtitles[$n].="$currLine ";
		}
	    } 
	}
    }	
    return %blocks;
}

sub printBlocks() {
    my (%blocks) = @_;
    my ($idx, $n);
    
#    foreach my $idx (sort {$a<=>$b} keys %blocks) {
#	printf("block n. %d:\n%s\n\n", $idx, join("\n", @{$blocks{$idx}}));
#    }
    
    for ($n=0; $n<=$#idxMap; $n++) {
	$idx=$idxMap[$n];
	printf("block n. %d (idx=%d):\n", $n, $idx);
	printf("%s\n", printBlock(0, $idx, @{$blocks{$n}}));
	printf("subtitle: %s\n\n", $subtitles[$n]);
    }
}

sub printBlock() {
    my ($hthr, $idx, @block) = @_;

    printf("%d\n", $idx); # index of the block
    printf("%s\n", $block[0]); # timing: "hh:mm:ss,dd --> hh:mm:ss,dd"

    # print subtitle (text):
    for (my $i=1; $i<=$#block; $i++) {
	if ($block[$i] cmp "__EOB__") {
	    if ($hthr>0) {
		printf("%s\n", &rmHHallucination($hthr, $block[$i])); 
		# Nota:
		# Se il testo del blocco e` segmentato su piu` linee, 
		# le allucinazioni orizzontali vengono eliminate 
		# all'interno di ogni linea, NON dell'intero testo. 
		# L'intero testo sarebbe disponibile in $subtitles[], 
		# ma dopo la rimozione delle allucinazioni andrebbe di
		# nuovo segmentato in linee, cosa problematica da fare...

	    } else {
		printf("%s\n", $block[$i]);
	    }
	}
    }
    # print empty line as a separator of the successive blocks:
    printf("\n");
}

sub rmHHallucination{
        my ($thr,$in) = @_;
        my ($idx, $hallLen);

        $in=~s/[ \t]+/ /g; $in=~s/^ | $//g;

        my @wrd=split(/ /, $in);
	$idx=0;

	while ($idx<$#wrd) {
		$hallLen=&computeHallLen($idx, @wrd);
		printf("idx=$idx hallLen=$hallLen\n") if ($verbose);
		if ($hallLen>=$thr) {
			@tmp=(@wrd[0..$idx],@wrd[$idx+$hallLen..$#wrd]); 
			printf("tmp=[%s]\n", join(" ", @tmp)) if ($verbose);
			@wrd=@tmp;
			printf("new wrd=[%s]\n", join(" ", @wrd)) if ($verbose);
		}
		$idx++;
	}
	printf("final wrd=[%s]\n", join(" ", @wrd)) if ($verbose);
	return join(" ", @wrd);
}

sub computeHallLen() {
	# conta quante sono le parole a dx di quella corrente uguali ad essa (1 se non ce ne sono)
	my ($start,@w) = @_;
	my ($i, $hallLen);
	$i=$start+1;
        while ($i<=$#w && $w[$start] eq $w[$i]) {$i++};
	$hallLen=$i-$start; 
	printf ("start=$start i=$i hallLen=$hallLen\n") if ($verbose);
	return $hallLen;
}

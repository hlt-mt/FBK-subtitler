#!/bin/bash


wDir=$(cd $(dirname $0); pwd)
scriptFolder=/home/cattoni/wrk/SpeechTranslation/AI4Culture/storage/ST/scripts

test $# -ge 1 || { echo 'ARGS srt' ; exit 1 ; } 
srt=$1
outSrt=$2


test -f $srt || { echo cannot find srt $srt ; exit 1 ; }

cat $srt | egrep '^[0-9]+$|\-\->|^$'| uniq \
  | perl -pe 's/^$/dummy\n/'\
  | perl $scriptFolder/mergeSrtTxt.pl <(cat $srt | perl $scriptFolder/srt2txt.pl) 


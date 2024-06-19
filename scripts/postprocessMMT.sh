#!/bin/bash

#1: ModernMT output file
#2: cleaned ModernMT output file

scriptFolder=$(dirname $0)


cat $1 | perl -pe 's/Ԋ/ \$\{DNT1\} /g; s/Ꙁ/ \$\{DNT0\} /g; s/[ \t]+/ /g; s/^ | $//g' | sed '/^$/d' | python3 $scriptFolder/RemoveSequenceDNT.py | python3 $scriptFolder/CheckLastWord.py $2


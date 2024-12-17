#!/bin/bash


# ARGS:
#1: wavFile
#2: srcLang
#3: tgtLang
#4: outSrt
#5: stateFile


wDir=$(cd $(dirname $0) ; pwd)
maxCharacters=40
maxLines=2

function fail_exit() {
    stateFile=$1
    outSrt=$2
    
    # write stateFile
    echo fail > $stateFile
    
    # write empty srt
    cat - <<EOF > $outSrt
1
00:00:00,000 --> 00:00:01,000
EMPTY_SUBTITLES

EOF
    exit 1
}


function translateWithHelsinkiWrapper() {
    sl=$1
    tl=$2
    inF=$3
    outF=$4
    tmpOut=/tmp/wh.$$.out
    : > $tmpOut
    Nin=$(wc -l < $inF)
    Nout=$(wc -l < $tmpOut)
    while [ $Nout -lt $Nin ] ; do
        doneN=$(( $Nout + 1 ))
        tail -n +$doneN $inF | python $exe8 $sl $tl >> $tmpOut 2> /dev/null
	Nout=$(wc -l < $tmpOut)
        if [ $Nout -lt $Nin ] ; then
            echo "Translation Error" >> $tmpOut
	    Nout=$(wc -l < $tmpOut)
        fi
    done
    cat $tmpOut > $outF
    \rm -f $tmpOut
}

function srtFinalCheckAndFillEmpty() {
    srt=$1

    size=$(wc -c < $srt 2>/dev/null | awk '{print $1}' )
    if ! test -f $srt ; then size=0 ; fi

    if test $size -lt 35
    then
      echo fixing empty $srt:
      cat - <<EOF > $srt
1
00:00:00,000 --> 00:00:01,000
EMPTY_SUBTITLES

EOF
    fi
}


test $# -ge 5 || { echo 'ARGS: wav srcLang tgtLang outSrt stateFile' ; exit 1 ; }
wav=$1
src=$2
tgt=$3
outSrt=$4
stateFile=$5

cat << EOF
args:
  wav $wav
  srcLang $src 
  tgtLang $tgt 
  outSrc $outSrt 
  stateFile $stateFile
EOF

test -f $wav || { echo cannot find wav $wav ; fail_exit $stateFile $outSrt ; }
case $src in
  en|es|fr|it|pt)
      prefix=$src
      ;;
  *)
      prefix=multi
      ;;
esac
ckpt=$HOME/.cache/shas/${prefix}.checkpoint
test -f $ckpt || { echo cannot find chkpt $ckpt ; fail_exit $stateFile $outSrt ; }

_dd=$(dirname $outSrt)
test -d $_dd || { echo cannot find directory of $outSrt ; fail_exit $stateFile $outSrt ; }
test -w $_dd || { echo directory of $outSrt is not writable ; fail_exit $stateFile $outSrt ; }
unset _dd

if ! test -z "$logDir"
then
  _dd=$(dirname $logDir)
  test -d $_dd || { echo cannot find directory of $logDir ; fail_exit $stateFile $outSrt ; }
  test -w $_dd || { echo directory of $logDir is not writable ; fail_exit $stateFile $outSrt ; }
  unset _dd
fi

scriptDir=$wDir/scripts

exe1=${SHAS_ROOT}/src/supervised_hybrid/segment.py
exe2=$scriptDir/createWavFromShasSegm.py
exe3=faster-whisper
exe4_1=$scriptDir/srtFixTS.pl
exe4_2=$scriptDir/srt_fix_duration.pl
exe4_3=$scriptDir/rmHallucinations.pl
exe5=$scriptDir/joinSrtFromShasSegm.py
exe6=$scriptDir/srtPostprocess.pl
exe7=$scriptDir/srt2txt.pl
exe8=$scriptDir/helsinki_opus_mt.py
exe9=$scriptDir/src2trgSrt.pl
exe10=$scriptDir/splitSentences4matesub_naive.pl

for f in $exe1 $exe2 $exe4_1 $exe4_2 $exe4_3 $exe5 $exe6 $exe7 $exe8 $exe9 $exe10
do
  test -f $f || { echo cannot find exe $f ; fail_exit $stateFile $outSrt ; }
done

echo run $0 on $(uname -n) ; echo
echo START $(date +%s)

tmpWavD1=/tmp/psfw.$$.audio.1
! test -d $tmpWavD1 || rm -rf ${tmpWavD1}
mkdir ${tmpWavD1}
#
tmpOutY=/tmp/psfw.$$.yaml
! test -f $tmpOutY || rm -f ${tmpOutY}
#
tmpWavD2=/tmp/psfw.$$.audio.2
! test -d $tmpWavD2 || rm -rf ${tmpWavD2}
mkdir ${tmpWavD2}
#
tmpSrtD1=/tmp/psfw.$$.srt.1
! test -d $tmpSrtD1 || rm -rf ${tmpSrtD1}
mkdir ${tmpSrtD1}
#
tmpSrtD2=/tmp/psfw.$$.srt.2
! test -d $tmpSrtD2 || rm -rf ${tmpSrtD2}
mkdir ${tmpSrtD2}
#
tmpJoinSrtD=/tmp/psfw.$$.joinSrt
! test -d $tmpJoinSrtD || rm -rf ${tmpJoinSrtD}
mkdir ${tmpJoinSrtD}
#
tmpSrtF=/tmp/psfw.$$.srt
! test -f $tmpSrtF || rm -f ${tmpSrtF}


cp $wav $tmpWavD1
bName=$(basename $wav .wav)

yamlF=${tmpOutY}
maxSegLen=15

# STEP 1
#
echo doing step 1 $(date +%s)
source /opt/env/shas/bin/activate
echo python $exe1 -wavs $tmpWavD1 -ckpt $ckpt -yaml $yamlF -max $maxSegLen
python $exe1 -wavs $tmpWavD1 -ckpt $ckpt -yaml $yamlF -max $maxSegLen


# STEP 2
#
echo doing step 2 $(date +%s)
$exe2 --segmentation-yaml $yamlF --wav-dir $tmpWavD1 --out-dir $tmpWavD2


# STEPS 3 and 4
#
echo doing steps 3 and 4 $(date +%s)
deactivate
source /opt/env/fw/bin/activate
export HF_DATASETS_OFFLINE=1

args="--language $src --task transcribe --model_size_or_path large-v3"
args="$args --vad_filter True"

for wav in $tmpWavD2/*wav
do
  fn=$(basename $wav .wav)
  srtF=$tmpSrtD1/${fn}.srt
  startSec=$(date +%s)
  echo $exe3 $args $wav -o $srtF
  $exe3 $args $wav -o $srtF
  endSec=$(date +%s)
  runSecs=$(expr $endSec - $startSec)
  echo runSecs $runSecs for $wav
  # skip empty srt
  if test $(wc -c < $srtF) -eq 0 ; then continue ; fi
  rmh=$tmpSrtD2/${fn}.srt
  cat $srtF | $exe4_1 | $exe4_2 | $exe4_3 --inType srt > $rmh
done
echo

# STEP 5
#
echo doing step 5 $(date +%s)
# join the segments srt into a single srt
$exe5 --segmentation-yaml $yamlF --srt-dir $tmpSrtD2 --out-dir $tmpJoinSrtD
srt=$tmpJoinSrtD/${bName}.srt
# clean the srt 
cat $srt | $exe4_3 --inType srt | $exe6 > $tmpSrtF
cat $tmpSrtF > $srt   

# STEP 6
#
echo doing step 6 $(date +%s)

srt=$tmpJoinSrtD/${bName}.srt
txtSrc=${srt}.txt.src
txtTgt=${srt}.txt.tgt
# extract the src text
$exe7 < $srt > $txtSrc

# translate the text with helsinki wrapper
deactivate
source /opt/env/helsinki/bin/activate
echo translateWithHelsinkiWrapper $src $tgt $txtSrc $txtTgt
translateWithHelsinkiWrapper $src $tgt $txtSrc $txtTgt

# re-compose the srt with the translated text
srtTgt=${txtTgt}.srt
$exe9 $srt $txtTgt > $srtTgt

# split blocks into lines (naive approach)
cat $srtTgt | $exe10 -c $maxCharacters -b $maxLines \
    | perl -pe 's/\s*\$\{DNT1\}\s*/\n/g' > $tmpSrtF
cat $tmpSrtF > $srtTgt

# check and fix final srt
srtFinalCheckAndFillEmpty $srtTgt

# cp the final srt into the outSrt
cat $srtTgt > $outSrt

echo END $(date +%s)

echo

if ! test -z "$logDir"
then
  test -d $logDir || mkdir -p $logDir
  cp -rf $tmpWavD1 $tmpWavD2 $tmpSrtD1 $tmpSrtD2 $tmpJoinSrtD $yamlF $logDir
  echo copied $tmpWavD1 $tmpWavD2 $tmpSrtD1 $tmpSrtD2 $tmpJoinSrtD $yamlF in $logDir
fi
rm -rf $tmpWavD1 $tmpWavD2 $tmpSrtD1 $tmpSrtD2 $tmpJoinSrtD $yamlF $tmpSrtF
echo done rm -rf $tmpWavD1 $tmpWavD2 $tmpSrtD1 $tmpSrtD2 $tmpJoinSrtD $yamlF $tmpSrtF

echo ready > $stateFile
echo updated $stateFile with state \"ready\"


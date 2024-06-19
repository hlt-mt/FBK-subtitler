#! /bin/bash

wDir=$(cd $(dirname $0) ; pwd)

cd $wDir

check_running() {
  ps $(cat $pidF) &> /dev/null
}


export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

pidF=$wDir/httpserver.PID
log=$wDir/httpserver.LOG
exe=$wDir/httpserver.py

if test -f $pidF 
then
  if check_running
  then
    echo WARNING: httpserver already running ... ; exit 1
  fi
fi

date > $log
echo python3 -u $exe "$@"  >>$log
python3 -u $exe "$@" 1>>$log 2>&1 & 
echo $! > $pidF 
printf "."
sleep 2

check_running || { echo ERROR: startup failed, check $log file ; exit 2 ; }

while ! grep '^web service ready at port ' $log &>/dev/null
do
  printf "."
  sleep 2
done

echo  
echo started httpserver with pid $(cat $pidF)

# block forever without polling
tail -f /dev/null


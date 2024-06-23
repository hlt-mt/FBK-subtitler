#! /bin/bash

if test -L $0 ; then exe=$(readlink -e $0) ; else exe=$0 ; fi
wDir=$(cd $(dirname $exe) ; pwd)  ; unset exe


dockerName=main
if ! docker logs $dockerName &> /dev/null
then
  echo docker container $dockerName is not running
else
  docker container kill $dockerName
  echo ended docker container pipeline main
fi

echo successfully ended FBK subtitler



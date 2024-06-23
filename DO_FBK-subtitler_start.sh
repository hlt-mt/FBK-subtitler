#! /bin/bash

if test -L $0 ; then exe=$(readlink -e $0) ; else exe=$0 ; fi
wDir=$(cd $(dirname $exe) ; pwd)  ; unset exe


if test -z "${FBK_DATA_PATH}"
then
  echo 'cannot find enviroment variable FBK_DATA_PATH: please set it with the path of the directory "FBK_data"'
  exit 1
fi

if ! test -d "${FBK_DATA_PATH}"
then
  echo 'ERROR: the value of the enviroment variable FBK_DATA_PATH is not a directory: please set it with the path of the directory "FBK_data"'
  exit 1
fi

if ! test -d "${FBK_DATA_PATH}/.cache"
then
  echo 'ERROR: the value of the enviroment variable FBK_DATA_PATH does not appear to contain the correct directory "FBK_data": please set it with the path of the directory "FBK_data"'
  exit 1
fi

dataDir=${FBK_DATA_PATH}

startMainDocker() {
  dockerImg=$1

  dockerNet="fbk"
  dockerName=main
  #
  docker network ls | grep ${dockerNet} &> /dev/null || docker network create ${dockerNet}
  #
  pars="--runtime=nvidia -d --rm -it -p 8080:8080"
  pars="$pars --net $dockerNet --name $dockerName"
  pars="$pars --shm-size 8G"
  pars="$pars -v ${FBK_DATA_PATH}/.cache:/root/.cache"
  #
  if test $# -gt 1
  then
      echo docker run $pars $dockerImg $cmd
  fi
  #
  cId=$(docker run $pars $dockerImg)
  echo successfully started $dockerName docker container $cId
}


# 1) start the pipeline main
#
dockerImg="fbk_subtitler:v1.2.1"
if docker container ls -a | grep "$dockerImg" &> /dev/null
then
  echo pipeline main container is already running 
else
  echo starting docker container pipeline main
  startMainDocker $dockerImg "$@"
fi
echo

echo FBK subtitler ready


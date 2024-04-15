# FBK AI4C-CSC subtitler
Repository containing the open source code of the subtitler developed by the [FBK MT unit](https://mt.fbk.eu/) under the European Union project "[AI4Culture: An AI platform for the cultural heritage data space](https://pro.europeana.eu/project/ai4culture-an-ai-platform-for-the-cultural-heritage-data-space)" (Action number 101100683).

## Release
FBK AI4C-CSC subtitler v1.2

##  Requirements
The FBK AI4C-CSC subtitler requires:
1. a GPU card (tested on Tesla K80)
2. a Linux OS (tested on Ubuntu 20.04, with nvidia drivers 470, CUDA 11.4 and cudnn 8)
3. a working docker installation

# Installation
## Download
Three files have to be downloaded:
1. the [main docker image](https://fbk.sharepoint.com/:u:/s/MTUnit/EZj6MT7Mro5JjKHz4H2criUB2QTlPChDCICPN3RUdFay1g?e=0egwxj) (around 7.5 GB)
2. the [FBK data archive v1.2](https://fbk.sharepoint.com/:u:/s/MTUnit/EY_usL_dbypJrDzYZP-hWJkBqemsbbD4CHrB27dpZ_Slew?e=m0fzUT) (around 4.3 GB)
3. the [script archive v1.2](https://fbk.sharepoint.com/:u:/s/MTUnit/ERxRiuN9LdNBgcrpFp4FgYkB5kGRnw0NKUFJsriCj1VH5g?e=bmwsVa) (around 1.5 KB)

## Add the docker image
Once downloaded the compressed docker image (docker_img_fbk_subtitler_v1_2.tar.gz)), it has to be added to your docker environment:
```
docker load < docker_img_fbk_subtitler_v1_2.tar.gz
```
At this point please check that the "fbk_subtitler:v1.2" is available in the list provided by the command:
```
docker image ls -a
```

## Extract archives
Extract the archive of the FBK data:
```
tar xvfz FBK_data_v1_2.tar.gz
```
This operation should end with the directory "FBK_data", whose size is around 5.8 GB.
There are no constraints on the position of the "FBK_data" directory inside the file system.

Extract the archive of the scripts :
```
tar xvfz scripts_v1_2.tar.gz
```
This provides two bash scripts:
1. DO_FBK-subtitler_start.sh
2. DO_FBK-subtitler_end.sh

# Start / End the FBK subtitler service
The FBK subtitler works as a webservice.

First of all the environment variable FBK_DATA_PATH must be set with the value of the path of the "FBK_data" directory:
```
export FBK_DATA_PATH=/path/to/FBK_data
```

To start the FBK subtitler service issue the command
```
bash DO_FBK-subtitler_start.sh
```
A set of messages are reported: please wait until this message appears
```
FBK subtitler ready
```

To end the FBK subtitles pipeline issue the command
```
bash DO_FBK-subtitler_end.sh
```
A set of messages are reported: please wait until this message appears
```
successfully ended FBK subtitler
```

# Usage
To use the FBK subtitler service, please read the [API specification document](https://docs.google.com/document/d/1WC8WcEfOibmNFhZWqMAJDqszL3xPTTc3SFoFGG0yHOs/edit?usp=sharing)

# Contacts
Please email cattoni AT fbk DOT eu

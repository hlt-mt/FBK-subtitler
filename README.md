# FBK AI4C-CSC subtitler
Repository containing the open source code of the subtitler developed by the [FBK MT unit](https://mt.fbk.eu/) under the European Union project "[AI4Culture: An AI platform for the cultural heritage data space](https://pro.europeana.eu/project/ai4culture-an-ai-platform-for-the-cultural-heritage-data-space)" (Action number 101100683).

##  Requirements
The FBK AI4C-CSC subtitler requires:
1. a GPU card (tested on Tesla K80)
2. a Linux OS (tested on Ubuntu 20.04, with nvidia drivers 470, CUDA 11.4 and cudnn 8)
3. a working docker installation

# Installation

1. clone this repo
```
git clone https://github.com/hlt-mt/FBK-subtitler
```

2. change into the tool directory
```
cd FBK-subtitler
```

4. build the docker image
```
docker build .
```


# Start / End the FBK subtitler service
The FBK subtitler works as a webservice.

To start the FBK subtitler service issue the command
```
docker run fbk_subtitler
```
A set of messages are reported: please wait until this message appears
```
FBK subtitler ready
```

# Usage
To use the FBK subtitler service, please read the [API specification document](https://docs.google.com/document/d/1WC8WcEfOibmNFhZWqMAJDqszL3xPTTc3SFoFGG0yHOs/edit?usp=sharing)

# Contacts
Please email cattoni AT fbk DOT eu

-----------------
1. USE THE SERVER
-----------------

1.1 Start an interactive job on a GPU node requisting a GPU

E.g.
$> srun -p gpu-K80 --gres=gpu:1 --mem=50G --pty bash


Once in the node (named here $GPU_NODE), do the next steps:

1.2 Set the environment

Set the environment variable FBKSUB_SERVERDATA_PATH
   should contain the path of a user directory where the server will put temporary data. Important: the directory must be writable.
   The directory is cleaned at start time.

E.g.
  export FBKSUB_SERVERDATA_PATH=/home/cattoni/wrk/AI4C/singularity/data


1.3 Run the server

Issue the command:
  /home/cattoni/wrk/AI4C/singularity/DO_FBK-subtitler_start.sh

To check it is running, issue the command:
  /home/cattoni/wrk/AI4C/singularity/DO_FBK-subtitler_check.sh


Keep the interactive job active and use the client (cfr. section 2) in another window.

IMPORTANT: at the end of the usage session, before exiting the srun command, DO NOT FORGET to end the server with the command:
  /home/cattoni/wrk/AI4C/singularity/DO_FBK-subtitler_end.sh




-----------------
2. USE THE CLIENT
-----------------

2.1 Start an interactive job on the same gpu node where the server runs

E.g.
$> srun -p gpu-K80 -w $GPU_NODE --mem=10G --pty bash


Once in the node $GPU_NODE, do the next steps:
2.2 Set the environment
Set environment variable IP to "localhost"
  export IP=localhost

2.3 Run the command

Use the commands:
  - /home/cattoni/wrk/AI4C/client/DO_client_GET_1.sh
  - /home/cattoni/wrk/AI4C/client/DO_client_GET_2.sh
  - /home/cattoni/wrk/AI4C/client/DO_client_POST.sh
according to the specs of the g-doc 
  https://docs.google.com/document/d/1WC8WcEfOibmNFhZWqMAJDqszL3xPTTc3SFoFGG0yHOs/edit?usp=sharing


<EOD>


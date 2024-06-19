#! /usr/bin/env python3

# Copyright 2023 FBK

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
import argparse
import re
import os
import yaml
import subprocess
import signal

def getTsString(seconds): 
    h = int(seconds / 3600)
    m = int((seconds - h * 3600) / 60)
    s = float(seconds - h * 3600 - m * 60)
    ## print(f'getTsString {seconds} => {h} {m} {s}')
    return '{:02d}:{:02d}:{:02.3f}'.format(h, m, s)

def main(args):
    yamlF = args.yaml
    segL = yaml.load(open(yamlF), Loader=yaml.FullLoader)
    for seg in segL:
        startS = seg["offset"]
        tsS    = getTsString(startS)
        dur    = seg["duration"]
        teS    = getTsString(float(startS)+float(dur))
        print(f'{startS} {dur} {tsS} {teS}')
        ## print(f'  eInfo {eInfo}')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    # I/O related arguments
    parser.add_argument(
        'yaml', help="the yaml file with SHAS segmentation info")
    main(parser.parse_args())


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


# to avoid children processes created by subprocess remain zombie
signal.signal(signal.SIGCHLD, signal.SIG_IGN)

def shell_exec(cmd, stdin=None, stdout=subprocess.PIPE, stderr=subprocess.PIPE, background=False, env=None):
    str_cmd = cmd if isinstance(cmd, str) else ' '.join(cmd)
    message = None
    if background:
        if stdout == subprocess.PIPE:
            stdout = DEVNULL
        if stderr == subprocess.PIPE:
            stderr = DEVNULL
    elif stdin is not None and isinstance(stdin, str):
        message = stdin
        stdin = subprocess.PIPE

    process = subprocess.Popen(cmd, stdin=stdin, stdout=stdout, stderr=stderr, shell=isinstance(cmd, str), env=env)

    stdout_dump = None
    stderr_dump = None
    return_code = 0

    if message is not None or stdout == subprocess.PIPE or stderr == subprocess.PIPE:
        stdout_dump, stderr_dump = process.communicate(message)
        return_code = process.returncode
    elif not background:
        return_code = process.wait()

    if background:
        return process
    else:
        if stdout_dump is not None:
            stdout_dump = stdout_dump.decode('utf-8')
        if stderr_dump is not None:
            stderr_dump = stderr_dump.decode('utf-8')

        if return_code != 0:
            raise ShellError(str_cmd, return_code, stderr_dump)
        else:
            return stdout_dump, stderr_dump

def shell_exec_background(cmd, stdin=None, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=None):
    ## print(f'ROL-1 shell_exec_background {cmd} {stdin} {stdout} {stderr}')
    shell_exec(cmd, stdin=stdin, stdout=stdout, stderr=stderr, env=env, background=True)

def shell_exec_foreground(cmd, stdin=None, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=None):
    ## print(f'ROL-1 shell_exec_foreground {cmd} {stdin} {stdout} {stderr}')
    shell_exec(cmd, stdin=stdin, stdout=stdout, stderr=stderr, env=env, background=False)



def getTsString(seconds):
    h = int(seconds / 3600)
    m = int((seconds - h * 3600) / 60)
    s = float(seconds - h * 3600 - m * 60)
    return '{:02d}:{:02d}:{:02.2f}'.format(h, m, s)

def main(args):
    wavD  = args.wav_dir
    outD  = args.out_dir
    yamlF = args.segmentation_yaml
    print(f'wavD {wavD}, yamlF {yamlF}, outD {outD}')
    segL = yaml.load(open(yamlF), Loader=yaml.FullLoader)
    # {duration: 3.023, offset: 20.1201, rW: 0, speaker_id: NA, uW: 0, wav: 11836.wav}
    # ffmpeg -i input.mp3 -ss 00:00:30 -to 00:01:45 out.mp3
    print(f'found {len(segL)} segments')
    exe = "ffmpeg"
    cntDict = dict()
    for seg in segL:
        wn     = seg["wav"]
        bn     = wn.replace(".wav", "")
        wavF   = wavD + "/" + wn
        startS = seg["offset"]
        tsS    = getTsString(startS)
        dur    = str(seg["duration"])
        if bn in cntDict:
            cnt = cntDict[bn] + 1
        else:
            cnt = 1
        cntDict[bn] = cnt
        ## print(f'  cntDict {cntDict}')
        outF   = outD + "/" + '{:}_{:03d}.wav'.format(bn, cnt)
        cmd = [exe, '-i', wavF, '-ss', tsS, '-t', dur, '-nostdin', '-y', outF]
        print(f'  shell_exec_foreground {cmd}')
        eInfo = shell_exec_foreground(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        ## print(f'  eInfo {eInfo}')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    # I/O related arguments
    parser.add_argument(
        '--wav-dir', type=str, required=True, help="the directory with the wav files")
    parser.add_argument(
        '--segmentation-yaml', type=str, required=True, help="the yaml file with SHAS segmentation info")
    parser.add_argument(
        '--out-dir', type=str, required=True, help="the directory to put the output wav files")
    main(parser.parse_args())


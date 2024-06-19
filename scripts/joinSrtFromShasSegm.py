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
import os.path
import yaml

dbgFlag = False 

def getTsString(seconds):
    h = int(seconds / 3600)
    m = int((seconds - h * 3600) / 60)
    s = int(seconds - h * 3600 - m * 60)
    r = int((seconds - h * 3600 - m * 60 - s) * 1000)
    return '{:02d}:{:02d}:{:02d},{:03d}'.format(h, m, s, r)

def getSrtInfo(srtContentL):
    lastEndTS = -1;
    blockL = []
    blockContent = ""
    blockStartT = -1
    blockEndT = -1
    inBlockFlag = False
    # -----------
    # srt example
    # -----------
    # 1
    # 00:00:00,000 --> 00:00:04,840
    # (fw 0.00 --> 4.50)
    # Sappiamo che bla bla bla
    #
    # 2
    # 00:00:05,000 --> 00:00:08,500
    # (fw faster-whisper 5.00 --> 8.50)
    # Inoltre sappiamo che bla bla bla
    #
    for line in srtContentL:
        # matches the block id (block first line)
        m1 = re.match('^\s*\d+\s*$', line)
        # matches the block time stamps (block second line)
        m2 = re.match('^(\d+):(\d+):(\d+),(\d+) --> (\d+):(\d+):(\d+),(\d+)', line)
        # matches the empty line (block end)
        m3 = re.match('^\s*$', line)
        if m1:
            inBlockFlag = True
        elif m2:
            blockStartT = float(m2.group(1)) * 3600 + float(m2.group(2)) * 60 + float(m2.group(3)) + float(m2.group(4)) / 1000
            blockEndT = float(m2.group(5)) * 3600 + float(m2.group(6)) * 60 + float(m2.group(7)) + float(m2.group(8)) / 1000 
            lastEndTS = blockEndT
        elif m3:
            blockInfo = { "content": blockContent, "start": blockStartT, "end": blockEndT }
            blockL.append(blockInfo)
            inBlockFlag = False
            blockContent = ""
        else:
            blockContent += line + "\n"
    return (lastEndTS, blockL)

def getTotalDuration(blockL):
    totDur = 0
    for blockInfo in blockL:
        totDur += (blockInfo["end"] - blockInfo["start"])
    return totDur

def debug(msg):
    if dbgFlag:
        print(msg)

def main(args):
    global dbgFlag
    srtD  = args.srt_dir
    outD  = args.out_dir
    yamlF = args.segmentation_yaml
    if (args.debug):
        dbgFlag = True
    print(f'srtD {srtD}, yamlF {yamlF}, outD {outD}, dbgFlag {dbgFlag}')
    segL = yaml.load(open(yamlF), Loader=yaml.FullLoader)
    # {duration: 3.023, offset: 20.1201, rW: 0, speaker_id: NA, uW: 0, wav: 11836.wav}
    print(f'found {len(segL)} segments')
    curWav = ""
    segCnt = 0
    fout = ""
    blockCnt = 0
    emptySrtFlag = True
    globalEndTs = 0.0
    for seg in segL:
        wn      = seg["wav"]
        bn      = wn.replace(".wav", "")
        offsetS = seg["offset"]
        durS    = seg["duration"]
        globalEndTs = offsetS + durS
        debug(f'  wn {wn}, offsetS {offsetS}, durS {durS}')
        if wn != curWav:
            curWav = wn
            segCnt = 0
            blockCnt = 0
            outF = outD + "/" + bn + ".srt"
            if fout:
                fout.close()
            fout = open(outF, "w")
        segCnt += 1
        srtF = srtD + "/" + '{:}_{:03d}.srt'.format(bn, segCnt)

        if not os.path.exists(srtF):
            debug(f'  srtF not exists')
            continue
        # read the srtF
        debug(f'  processing srtF {srtF}')
        srtContentL = []
        with open(srtF) as fin:
            for line in fin:
                line = line.rstrip()
                srtContentL.append(line)
        # check if the end timestamp of the last block is <= block duration
        (lastEndTS, blockL) = getSrtInfo(srtContentL)
        if lastEndTS > durS:
            diffTS = lastEndTS - durS
        else:
            diffTS = 0
        print(f'INFO {segCnt}: {diffTS} {lastEndTS} {durS} with {len(blockL)}')
        if diffTS  > 0:
            newBlockL = []
            # fix timestamps of each block, rescaling wrt diffTS
            #
            totDuration = getTotalDuration(blockL)
            # 1) fix both startT and endT
            totSubtract = 0
            firstBlockFlag = True
            for blockInfo in blockL:
                newBI = blockInfo.copy()
                startS = newBI["start"]
                endS   = newBI["end"]
                bDur = (endS - startS)
                bSub = diffTS / totDuration * bDur
                totSubtract += bSub
                if not firstBlockFlag:
                    newBI["start"] = startS - totSubtract
                newBI["end"]   = endS - totSubtract
                newBlockL.append(newBI)
                firstBlockFlag = False
            # 2) fix startT if < the previous endT
            i = 1
            while i < len(newBlockL):
                currStart = newBlockL[i]["start"]
                prevEnd   = newBlockL[i-1]["end"]
                if currStart < prevEnd:
                    newBlockL[i]["start"] = prevEnd
                i += 1
            #
            # print for debug
            for i in range(len(newBlockL)):
                bi1 = blockL[i]
                s1 = getTsString(bi1["start"])
                e1 = getTsString(bi1["end"])
                bi2 = newBlockL[i]
                s2 = getTsString(bi2["start"])
                e2 = getTsString(bi2["end"])
                print(f'  CHANGED: {s1} -> {e1} INTO {s2} -> {e2}')
        else:
            newBlockL = blockL
        #
        # add the offsetS time to the timestamps of each block
        for blockInfo in newBlockL:
            startS = blockInfo["start"] + offsetS
            endS = blockInfo["end"] + offsetS 
            content = blockInfo["content"]
            blockCnt += 1
            print(blockCnt, file=fout)
            ts1 = getTsString(startS)
            ts2 = getTsString(endS)
            print(f'{ts1} --> {ts2}', file=fout)
            print(f'{content}', file=fout)
            emptySrtFlag = False
            debug(f'    writing {blockCnt} | {ts1} --> {ts2}')
    if fout:
        if emptySrtFlag:
            blockCnt = 1
            startS = 0.0
            endS = globalEndTs
            ts1 = getTsString(startS)
            ts2 = getTsString(endS)
            content = "EMPTY_SUBTITLES\n"
            print(blockCnt, file=fout)
            print(f'{ts1} --> {ts2}', file=fout)
            print(f'{content}', file=fout)
            debug('    emptySrtFlag')
        fout.close()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    # I/O related arguments
    parser.add_argument(
        '--segmentation-yaml', type=str, required=True, help="the yaml file with SHAS segmentation info")
    parser.add_argument(
        '--srt-dir', type=str, required=True, help="the directory with the segmented srt files")
    parser.add_argument(
        '--out-dir', type=str, required=True, help="the directory to put the joined srt files")
    parser.add_argument('-d', '--debug', action="store_true", help="debug")
    main(parser.parse_args())



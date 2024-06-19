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

try:
    import srt
except ImportError:
    print("Please install the srt package with 'pip install srt' and try again.")
    exit(1)


def main(args):

    with open(args.srt_file) as f:
        subtitles = list(srt.parse(f))
    for s in subtitles:
        #print(s)
        duration = float("{:.6f}".format((s.end.seconds+s.end.microseconds/1000000)-(s.start.seconds+s.start.microseconds/1000000)))
        strlen=len(re.sub(r"\s+", "", s.content))
        if(strlen==0):
            continue
        chardur=duration/strlen
        #print(duration,strlen,chardur)
        start=s.start.seconds+s.start.microseconds/1000000
        for w in s.content.split():
            print ("talkidXX 1", "{:.2f}".format(start), "{:.2f}".format(chardur*len(w)), w, "1.0")
            start+=chardur*len(w)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    # I/O related arguments
    parser.add_argument(
        '--srt-file', type=str, required=True, help="the SRT file")

    main(parser.parse_args())

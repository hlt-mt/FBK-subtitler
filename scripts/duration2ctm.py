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


def main(args):

    with open(args.in_file, 'r') as f:
        lines = f.readlines()
        count = 1
        for line in lines:
            #print("Line: {}".format(line.strip()))
            duration=float("{:.6f}".format(float(line.split()[0])))
            text=" ".join(line.split()[1:])
            #print("Duration = ", duration)
            #print("Text     = ", text)
            strlen=len(re.sub(r"\s+", "", text))
            if(strlen==0):
                continue
            chardur=duration/strlen
            #print(duration,strlen,chardur)
            #start=s.start.seconds+s.start.microseconds/1000000
            start=0.0
            for w in line.split()[1:]:
                print ("talkid{:d}".format(count),"1", "{:.2f}".format(start), "{:.2f}".format(chardur*len(w)), w, "1.0")
                start+=chardur*len(w)
            count+=1

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    # I/O related arguments
    parser.add_argument(
        '--in-file', type=str, required=True, help="the IN file (pairs: <duration> <sentence>")

    main(parser.parse_args())

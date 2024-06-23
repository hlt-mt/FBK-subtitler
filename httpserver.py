#!/usr/bin/env python3


def debug(msg):
    global DebugFlag
    if DebugFlag:
        print(msg)


# ---------------
# the http server
# ---------------
#

import http.server
import socketserver
import io
import cgi
import subprocess
import json
import os, sys
import traceback, logging
import argparse
import urllib.parse
import re
import random
import signal

# to avoid children processes created by subprocess remain zombie
signal.signal(signal.SIGCHLD, signal.SIG_IGN)

def shell_exec_background(cmd, stdin=None, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=None):
    print(f'ROL-1 shell_exec_background {cmd} {stdin} {stdout} {stderr}')
    str_cmd = cmd if isinstance(cmd, str) else ' '.join(cmd)
    #
    message = None
    if stdout == subprocess.PIPE:
        stdout = DEVNULL
    if stderr == subprocess.PIPE:
        stderr = DEVNULL
    #
    process = subprocess.Popen(cmd, stdin=stdin, stdout=stdout, stderr=stderr, shell=isinstance(cmd, str), env=env)
    #
    stdout_dump = None
    stderr_dump = None
    return_code = 0
    #
    return process


class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):

    def do_GET(self):        
        debug(f'do_GET {self.client_address}, {self.path}')
        parsed_path = urllib.parse.urlparse(self.path)
        query_parameters = urllib.parse.parse_qs(parsed_path.query)
        debug(f'parsed_path.path {parsed_path.path}, query_parameters {query_parameters}')

        # manage path
        #
        if re.search("project-state", parsed_path.path, re.IGNORECASE):
            # get the state of the subtitles project with given id
            if not "id" in query_parameters:
                info = 'missing mandatory attribute id'
                self.send_reply(400, info)
                return
            id = query_parameters['id'][0]
            state = self.get_state(id)
            ### generate a randome state
            ## stateDict = {0: "ready", 1: "processing", 2: "fail", 3: "unknown"}
            ## ri = random.randint(0, 3)            
            ## state = stateDict[ri]
            info = {"id": id, "state": state}
            self.send_reply(200, info)
            return
        elif re.search("project-subtitles", parsed_path.path, re.IGNORECASE):
            # serve the generated srt file of the subtitles project with given id
            if not "id" in query_parameters:
                info = 'missing mandatory attribute id'
                self.send_reply(400, info)
                return
            id = query_parameters['id'][0]
            state = self.get_state(id)
            if state != "ready":
                info = f'state for id {id} is {state} (not ready)'
                self.send_reply(400, info)
                return
            #
            srt_file = f'{RootDir}/out/{id}.srt'
            if not os.path.exists(srt_file):
                state = "fail"
                self.set_state(state)
                info = f'state for id {id} is {state}'
                self.send_reply(400, info)
                return
            self.send_srt_file(srt_file)
            return
        else:
            info = f'unknown GET path {self.path}'
            self.send_reply(400, info)

    def do_POST(self):
        if not self.check_availability_for_new_project():
            info = f'system is busy with a previous request'
            self.send_reply(400, info)
            return
        st, info, pars = self.deal_post_data()
        debug(f'do_POST {st}, {info}, {self.client_address}, {pars}')
        if st != 200:
            self.send_reply(st, f'{info}')
            return
        # set pars
        source = pars["source"]
        target = pars["target"]

        # manage the cases
        if pars["path"] == "/create-subtitling-project":
            # process audio file
            audiofile = pars["audiofile"]
            id = pars["id"]
            exe = pars["exe"]
            # call the pipeline
            log_out = f'{RootDir}/../../pipeline.LOG.out'
            log_err = f'{RootDir}/../../pipeline.LOG.err'
            in_wav  = f'{RootDir}/{audiofile}'
            out_srt = f'{RootDir}/out/{id}.srt'
            state_file = f'{RootDir}/sys/{id}.state'
            with open(log_out, "w") as fout:
                with open (log_err, "w") as ferr:
                    # inputWav sourceLanguage targetLanguage outSrt
                    cmd = [exe, in_wav, source, target, out_srt, state_file]
                    if DebugFlag:
                        cmd.append("-d")
                    shell_exec_background(cmd, stdout=fout, stderr=ferr)
            #
            self.set_state(id, "running")
            #
            ## self.rm_file(audiofile)
            info = {"id": id, "audiofile": audiofile}
            self.send_reply(200, info)

    def deal_post_data(self):
        global ExeCascade, ExeDirect
        form = cgi.FieldStorage(
            fp=self.rfile, 
            headers=self.headers,
            environ={'REQUEST_METHOD':'POST',
                     'CONTENT_TYPE':self.headers['Content-Type'],
                     })
        ctype, pdict = cgi.parse_header(self.headers['Content-Type'])
        # pdict contains 'boundary' if ctype == multipart/form-data, otherwiese pdict is empty
        #
        debug(f"deal_post_data 1 ctype {ctype}, path {self.path}, client_address {self.client_address}, form.keys() {form.keys()}")
        if ctype == 'multipart/form-data':
            # for fields with the same name take only the last value

            # parse common parameters langpair, power, verbosity, email
            audiofile = "" ; source = "" ; target = ""
            if not "audiofile" in form:
                return (400, "missing mandatory attribute audiofile", {})
            if not "source" in form:
                return (400, "missing mandatory attribute source", {})
            if not "target" in form:
                return (400, "missing mandatory attribute target", {})

            values = form.getlist("source")
            source = values[-1]
            values = form.getlist("target")
            target = values[-1]
            debug(f"deal_post_data 2 source {source}, target {target}")

            # manage source language
            if not re.match('(de|el|en|es|it|nl|ro|sl)', source):
                return (400, f'unsupported source {source}', {})

            # manage target language
            if not re.match('(de|el|en|es|it|nl|ro|sl)', target):
                return (400, f'unsupported target {target}', {})

            exe = ""
            # manage language pair
            if (re.match('(de|el|es|it|nl|ro|sl)', source) and re.match('en', target)):
                exe = ExeDirect
            elif (re.match('en', source) and re.match('(de|es|it|nl|ro)', target)):
                exe = ExeCascade
            else:
                return (400, f'unsupported language pair {source}-{target}', {})
            
            # manage path
            #
            if self.path == "/create-subtitling-project":
                field = "audiofile"
                if not field in form:
                    return (400, f'missing mandatory file {field}', {})
                item = form[field]
                if not item.file:
                    return (500, f'problems in uploading {field}', {})
                saved_file_path = f'./upload/{item.filename}'
                id = self.get_new_id();
                with open(saved_file_path, 'wb') as fp:
                    while True:
                        chunk = item.file.read(100000)
                        if not chunk:
                            break
                        fp.write(chunk)
                # 
                return (200, "ok", {"path":      self.path,
                                    "source":    source, 
                                    "target":    target,
                                    "exe":       exe,
                                    "id":        id,
                                    "audiofile": saved_file_path})
            # unknown path 
            #
            else:
                return (400, f'unknown POST path {self.path}', {})

    def send_reply(self, status, payload):
        response_dict = { "status" : status }
        if status == 200:
            response_dict["data"] = payload
        else:
            response_dict["error"] = payload
        response_jstring = json.dumps(response_dict)
        
        f = io.BytesIO()
        bytes = str.encode(response_jstring)
        f.write(bytes)
        length = f.tell()
        f.seek(0)
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.send_header("Content-Length", str(length))
        self.end_headers()
        if f:
            self.copyfile(f, self.wfile)
            f.close()
        debug(f'send_reply {response_dict}')

    def send_srt_file(self, srt_file):
        self.send_response(200)
        self.send_header('Content-type', 'txt/srt')
        self.end_headers()
        with open(srt_file, 'rb') as f: 
            self.wfile.write(f.read())
        debug(f'sent txt/srt file {srt_file}')

    def rm_file(self, path):
        try:
            os.remove(path)
        except OSError:
            pass

    def get_new_id(self):
        cntF = f'{RootDir}/sys/cnt.txt'
        try:
            with open(cntF) as fin:
                line = fin.readline()
                id = int(line)
            id += 1
            with open(cntF, "w") as fout:
                fout.write('%d\n' % id)
        except Exception:
            id = 1
        return id

    def get_state(self, id):
        stateF = f'{RootDir}/sys/{id}.state'
        try:
            with open(stateF) as fin:
                state = fin.readline().rstrip()
        except FileNotFoundError:
            state = "unknown"
        except Exception:
            state = "processing"
        return state

    def set_state(self, id, value):
        stateF = f'{RootDir}/sys/{id}.state'
        try:
            with open(stateF, "w") as fout:
                fout.write('%s\n' % value)
            res = True
        except Exception:
            res = False
        return res

    # return True:
    #   (1) if it is the first time request (no id or id==0) or
    #   (2) if the last project has been finished
    #   (3) if there is no state (state == "unknown")
    def check_availability_for_new_project(self):
        cntF = f'{RootDir}/sys/cnt.txt'
        if not os.path.exists(cntF):
            return True
        #
        id = 0
        try:
            with open(cntF) as fin:
                line = fin.readline()
                id = int(line)
        except Exception:
            return False
        #
        if id == 0:
            return True
        #
        state = self.get_state(id)
        if state == "ready" or state == "fail":
            return True
        if state == "unknown":
            return True
        return False


Port      = 8080
RootDir   = os.path.abspath(os.path.dirname(__file__)) + "/data"
DebugFlag = False

parser = argparse.ArgumentParser()
# (optional) args
parser.add_argument("-d", "--debug", action="store_true", help="enable debug")
parser.add_argument("-p", "--port", type=int, help=f"the port to accept connections (default {Port})")
parser.add_argument("-r", "--rootPath", help=f"the path of the directory where to read/write files {RootDir})")
args = parser.parse_args()

DebugFlag    = args.debug
if args.port:
    Port   = args.port
if args.rootPath:
    RootDir = args.rootPath

ExeCascade = f'{RootDir}/../../srv_pipeline_cascade.sh'
ExeDirect  = f'{RootDir}/../../srv_pipeline_direct.sh'

if __name__ == '__main__':
    try:
        # start the web server
        os.chdir(RootDir)
        Handler = CustomHTTPRequestHandler
        with socketserver.TCPServer(("", Port), Handler) as httpd:
            print(f"web service ready at port {Port}")
            httpd.serve_forever()

    except Exception as ex:
        tb = traceback.format_exc()
        logging.error(tb)
        sys.exit(1)


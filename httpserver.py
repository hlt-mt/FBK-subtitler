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
import threading



# to avoid children processes created by subprocess remain zombie
signal.signal(signal.SIGCHLD, signal.SIG_IGN)

def shell_exec_background(cmd, stdin=None, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=None):
    debug(f'shell_exec_background {cmd} {stdin} {stdout} {stderr}')
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

    # possible values are
    #   "todo" (to be processed), "running" (in process),
    #   "ready" (processed ok, SRT ready),
    #   "fail" (processed with problems), "unknown"
    #
    @classmethod
    def get_state_file(cls, id):
        stateF = f'{RootDir}/sys/{id}.state'
        try:
            with open(stateF) as fin:
                state = fin.readline().rstrip()
        except FileNotFoundError:
            state = "unknown"
        except Exception:
            state = "unknown"
        return state

    @classmethod
    def get_random_state(cls, id):
        # generate a randome state
        stateDict = {0: "todo", 1: "running", 2: "ready",
                     3: "fail", 4: "unknown"}
        ri = random.randint(0, 3)            
        state = stateDict[ri]
        return state

    @classmethod
    def set_state_file(cls, id, value):
        stateF = f'{RootDir}/sys/{id}.state'
        try:
            with open(stateF, "w") as fout:
                fout.write('%s\n' % value)
            res = True
        except Exception:
            res = False
        return res

    
    # the hash of id and related info (audioname, src, tgt, status)
    htIdTask = dict()

    @classmethod
    def getAudionameFromId(cls, id):
        id = int(id)
        if id in cls.htIdTask:
            return(cls.htIdTask[id]["audioname"])
        else:
            return("")

    @classmethod
    def setTaskFromId(cls, id, audioname, src, tgt, state, exe):
        id = int(id)
        cls.htIdTask[id] = {
            "audioname": audioname,
            "src": src, "tgt": tgt,
            "state": state, "exe": exe
        }

    @classmethod
    def print_htIdTask(cls):
        debug(f'  htIdTask {cls.htIdTask}')
    
    @classmethod
    def updateHtIdTaskWrtStateFiles(cls):
        for id in cls.htIdTask:
            stateT = cls.htIdTask[id]["state"]
            stateF = cls.get_state_file(id)
            if stateF != stateT :
                cls.htIdTask[id]["state"] = stateF
                debug(f'  updateHtIdTaskWrtStateFiles: {id} {stateT} {stateF}')
    
    
    @classmethod
    def bgCheckAndActivatePipeline(cls):
        global CheckSecs, RootDir, DebugFlag
        #
        # 1) read the state files and if there are "ready" states then
        #    update the corresponding task state
        cls.updateHtIdTaskWrtStateFiles()
        # 
        # 2) check if there is a todo task AND (2) no running tasks
        #    if yes then
        #      - start the first todo task
        #      - update its (both task and file) state to "running"
        #
        # find the first todo task
        todoTaskId     = None
        for id in sorted(cls.htIdTask):
            state = cls.htIdTask[id]["state"]
            if not todoTaskId and state.lower() == "todo":
                todoTaskId = id
                break
        # find the first running task
        runningTaskId  = None
        for id in sorted(cls.htIdTask):
            state = cls.htIdTask[id]["state"]
            if state.lower() == "running":
                runningTaskId = id
                break
        # check
        if todoTaskId:
            if not runningTaskId:
                debug(f'  starting todoTaskId {todoTaskId} (no running tasks)')
                task   = cls.htIdTask[todoTaskId]
                aName  = task["audioname"]
                audioF   = f'{RootDir}/upload/{aName}'
                src      = task["src"]
                tgt      = task["tgt"]
                outSrtF  = f'{RootDir}/out/{todoTaskId}.srt'
                stateF   = f'{RootDir}/sys/{todoTaskId}.state'
                #
                exe      = task["exe"]
                logOut   = f'{RootDir}/../../pipeline.LOG.out'
                logErr   = f'{RootDir}/../../pipeline.LOG.err'

                # args: audioF src tgt outSrtF, stateF 1> logOut 2> logErr
                cmd = [exe, audioF, src, tgt, outSrtF, stateF]
                if DebugFlag:
                    cmd.append("-d")
                with open(logOut, "w") as fout:
                    with open (logErr, "w") as ferr:
                        shell_exec_background(cmd, stdout=fout, stderr=ferr)
                
                # update stateT and stateF to "running"
                state = "running"
                cls.htIdTask[todoTaskId]["state"] = state
                cls.set_state_file(todoTaskId, state)
                debug(f'  started todoTaskId {todoTaskId}')
                cls.print_htIdTask()
        #
        threading.Timer(CheckSecs, cls.bgCheckAndActivatePipeline).start()


        
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
            state = self.get_state_file(id)
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
            state = self.get_state_file(id)
            if state != "ready":
                info = f'state for id {id} is {state} (not ready)'
                self.send_reply(400, info)
                return
            #
            srt_file = f'{RootDir}/out/{id}.srt'
            if not os.path.exists(srt_file):
                state = "fail"
                self.set_state_file(state)
                info = f'state for id {id} is {state}'
                self.send_reply(400, info)
                return
            self.send_srt_file(srt_file)
            return
        elif re.search("_dbg_get_audio", parsed_path.path, re.IGNORECASE):
            # serve the audio of the subtitles project with given id
            if not "id" in query_parameters:
                info = 'missing mandatory attribute id'
                self.send_reply(400, info)
                return
            id = query_parameters['id'][0]
            state = self.get_state_file(id)
            if state == "unknown":
                info = f'no subtitles projects for id {id}'
                self.send_reply(400, info)
                return
            #
            audio_name = self.getAudionameFromId(id)
            self.print_htIdTask()
            audio_file = f'{RootDir}/upload/{audio_name}'
            if not os.path.exists(audio_file):
                info = f'cannot find audio {audio_file} for id {id}'
                self.send_reply(400, info)
                return
            self.send_audio_file(audio_file)
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
            #
            state = "todo"
            self.set_state_file(id, state)
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
                id = self.get_new_id();
                fName = f'{id}_{item.filename}'
                saved_file_path = f'./upload/{fName}'
                with open(saved_file_path, 'wb') as fp:
                    while True:
                        chunk = item.file.read(100000)
                        if not chunk:
                            break
                        fp.write(chunk)
                state = "todo"
                self.setTaskFromId(id, fName, source, target, state, exe) 
                self.print_htIdTask()
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

    def send_audio_file(self, audio_file):
        self.send_response(200)
        self.send_header('Content-type', 'audio/wav')
        self.end_headers()
        with open(audio_file, 'rb') as f: 
            self.wfile.write(f.read())
        debug(f'sent wav file {audio_file}')

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


    # always return True
    #
    def check_availability_for_new_project(self):
        return True


Port      = 8080
RootDir   = os.path.abspath(os.path.dirname(__file__)) + "/data"
DebugFlag = False
CheckSecs = 10.0

parser = argparse.ArgumentParser()
# (optional) args
parser.add_argument("-d", "--debug", action="store_true", help="enable debug")
parser.add_argument("-p", "--port", type=int, help=f"the port to accept connections (default {Port})")
parser.add_argument("-r", "--rootPath", help=f"the path of the directory where to read/write files {RootDir})")
parser.add_argument("-c", "--checkSeconds", type=float, help=f"the seconds two sleep before checking task state changes (default {CheckSecs})")
args = parser.parse_args()

DebugFlag    = args.debug
if args.port:
    Port   = args.port
if args.rootPath:
    RootDir = args.rootPath
if args.checkSeconds:
    CheckSecs = args.checkSeconds

print(f'  DebugFlag {DebugFlag}, CheckSecs {CheckSecs}, Port {Port}, RootDir {RootDir}')
ExeCascade = f'{RootDir}/../../srv_pipeline_cascade.sh'
ExeDirect  = f'{RootDir}/../../srv_pipeline_direct.sh'

if __name__ == '__main__':
    try:
        # start the background activity
        CustomHTTPRequestHandler.bgCheckAndActivatePipeline()
        
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


#!/usr/bin/python
# -*- coding: utf8 -*-

import sys, os, re, fileinput, random





'''
Created on Set 3, 2019

@author: Marco Turchi (turchi@fbk.eu)
'''

     
def usage():
    print ("Wrong Number of Parameters ")
    print ("Usage: ")
    print ("python .py inputFileWithTags") 
    sys.exit()    
    
    
if __name__ == '__main__':
    argv = sys.argv
    if len(argv) != 2:
        usage()
    else:
        
        outfilename =argv[1] 
    
    file = open(outfilename,'w')   
   
    for line in sys.stdin:
        l = line.strip().split("/n")[0].strip()
        print(l)
        toks = l.split(" ")
        print(toks[-1])
        if (toks[-1] != "${DNT0}") and (toks[-1] != "${DNT1}"):
            #l = l + " ${DNT0}\n"
            toks.append("${DNT0}\n")
        elif (toks[-1] == "${DNT1}"):
            toks[-1] = "${DNT0}\n"
        else:
            toks.append("\n")
            #l = l + "\n"
        print(toks)
        file.write(" ".join(toks))
    file.close()
        

    
    

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
    print ("python .py ") 
    sys.exit()    
    
    
if __name__ == '__main__':
    

    
     
   
    for line in sys.stdin:
        l = line.strip().split("/n")[0].strip()
        #print(l+"\n")
        toks = l.split(" ")
        prev = ""

        finalList= []
        for t in toks:
            cur = t
            if("${DNT" in prev) and ("${DNT" in cur):
                cur = ""
            else:
                finalList.append(prev)
                prev = cur
        finalList.append(prev)
        print(" ".join(finalList).strip())

    
    

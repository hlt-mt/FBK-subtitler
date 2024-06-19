import sys, urllib.parse

for line in sys.stdin:
    print(urllib.parse.quote_plus(line, safe=""))

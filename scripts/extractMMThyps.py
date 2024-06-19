import sys, json;
try:
    data = json.load(sys.stdin)
except Exception as e:
    sys.exit("Error in loading JSON data from ModernMT")

try:
    print(data["data"]["translation"])
except Exception as e:
    sys.exit("Error in extracting 1best hyp from ModernMT")

if "altTranslations" in data["data"]:
    for i, tr in enumerate(data["data"]["altTranslations"]):
        print(" alternative %d: %s" % (i, tr))

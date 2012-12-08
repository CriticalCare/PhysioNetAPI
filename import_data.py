import json
import urllib
import urllib2
from glob import glob

"""
Import PhysioNet challenge data into CriticalCare

Usage: import_data.py [HOST] [PORT]
"""

def import_files(url):
    for filename in glob('*.txt'):
        with open(filename) as f:
            response = urllib2.urlopen(
                    url='http://%s/file' % url,
                    data=urllib.urlencode({'file': f.read()}))
            print response.read()
            response.close()

if __name__ == '__main__':
    import sys
    url = 'localhost:3000'
    if len(sys.argv) > 1:
        url = sys.argv[1]
    if len(sys.argv) > 2:
        url += ":%s" % sys.argv[2]
    import_files(url)

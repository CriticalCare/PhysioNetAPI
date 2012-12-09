import json
import urllib
import urllib2
from glob import glob

"""
Import PhysioNet challenge data into CriticalCare
"""

def import_files(url):
    for filename in glob('*.txt'):
        with open(filename) as f:
            response = urllib2.urlopen(
                    url='http://%s/file' % url,
                    data=urllib.urlencode({'file': f.read()}))
            print response.read()
            response.close()

def import_outcomes(url, filename):
    with open(filename) as f:
        response = urllib2.urlopen(
                url='http://%s/file' % url,
                data=urllib.urlencode({'outcomes': f.read()}))
        print response.read()
        response.close()

if __name__ == '__main__':
    from argparse import ArgumentParser
    parser = ArgumentParser(description=__doc__, add_help=True)
    parser.add_argument('--host', type=str, default='localhost',
            help='hostname, defaults to localhost')
    parser.add_argument('--port', type=str, help='port')
    parser.add_argument('--outcomes', type=str,
            help='Import an outcomes file (if not given all .txt files in the current directory will be imported as patient records)')
    args = parser.parse_args()
    url = args.host+':'+args.port if args.port else args.host
    if args.outcomes:
        import_outcomes(url, args.outcomes)
    else:
        import_files(url)

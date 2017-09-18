#!/usr/bin/python

import sys
import re
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--hash", "-H", type=str)
parser.add_argument("--ssn", "-s", action="store_true")
parser.add_argument("--password", "-p", action="store_true")
parser.add_argument("--secret", "-c", action="store_true")
parser.add_argument("--key", "-k", action="store_true")
args = parser.parse_args()

if args.ssn:
	regex = re.compile('[0-9]{3}-[0-9]{2}-[0-9]{4}')
elif args.password:
	regex = re.compile('password', re.IGNORECASE)
elif args.secret:
	regex = re.compile('secret', re.IGNORECASE)
elif args.key:
	regex = re.compile('key', re.IGNORECASE)

# print 'Extractor.py'

for line in sys.stdin.readlines():
	# print line
	matches = regex.findall(line)
	if matches:
		if args.hash:
			them_matches = "\t".join(matches)
			print "%s\t%s" % (args.hash, them_matches)
		else:
			print "\t".join(matches)

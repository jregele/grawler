#!/usr/bin/python

import sys
import re
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--hash", "-H", type=str, default=None)
parser.add_argument("--ssn", "-s", action="store_true")
parser.add_argument("--password", "-p", action="store_true")
parser.add_argument("--secret", "-c", action="store_true")
parser.add_argument("--key", "-k", action="store_true")
parser.add_argument("--custom", "-C", type=str, default=None)
args = parser.parse_args()

if args.ssn:
	regex = re.compile('[0-9]{3}-[0-9]{2}-[0-9]{4}')
elif args.password:
	regex = re.compile(r"password.*$", re.IGNORECASE)
elif args.secret:
	regex = re.compile(r"secret.*$", re.IGNORECASE)
elif args.key:
	regex = re.compile(r"key.*$", re.IGNORECASE)
elif args.custom:
	r = r"%s.*$" % args.custom
	regex = re.compile(r, re.IGNORECASE)

# print 'Extractor.py'

def dump(matches, hash=None, line=None):
	if line:
		print line
	elif hash:
		them_matches = "\t".join(matches)
		print "%s\t%s" % (args.hash, them_matches)
	else:
		print "\t".join(matches)

for line in sys.stdin.readlines():
	# print line
	matches = regex.findall(line)
	if matches:
		# if args.ssn:
		dump(matches, args.hash)
		# else:
		# 	# dump the entire line
		# 	dump(matches, args.hash, line)

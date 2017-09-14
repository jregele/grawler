#!/bin/bash

program_name=$0

GIT_DIR=
WORK=/tmp
FILTER=
EXTRACT=

SSN_EXTRACT='[0-9]{3}-[0-9]{2}-[0-9]{4}'
PW_EXTRACT='-i password'
SECRET_EXTRACT='-i secret'
KEY_EXTRACT='-i key'

usage() {
	echo "usage: $program_name [-sh] [-g dir] [-w dir] [-f filter] [-x regex]"
	echo "	-g 	git directory"
	echo "	-w 	working directory"
	echo "	-f 	filter for git log"
	echo "	-x 	extract regex"
	echo "	-s 	SSN extract"
	echo "	-p 	Password extract"
	echo "	-k 	Key extract"
	echo " 	-c 	Secret extract"
	echo "	-h 	print this cruft"
	echo "Only one type of extract may be performed at a time"
}

walk_tree() {
	# params 
	# hash = $1
	type=$(git cat-file -t $1)
	if [ "$type" = "blob" ]; then
		# echo $2
		git cat-file -p $1 | egrep $EXTRACT | awk 'match($0, /$EXTRACT/) { print substr( $0, RSTART, RLENGTH)}'
	else
		# git cat-file -p $2 | cut -d " " -f 3 | cut -d "	" -f 1
		subtrees=$(git cat-file -p $1 | cut -d " " -f 3 | cut -d "	" -f 1)
		for tree in $subtrees; do
			# pprint $tree $(($depth+1))
			# echo $tree
			walk_tree $tree
		done
	fi
}

while getopts "g:w:f:x:sh" opt; do
	case $opt in
		g)
			GIT_DIR=$OPTARG
			echo "Git directory is $GIT_DIR"
			;;
		w)
			WORK=$OPTARG
			echo "Working directory is $WORK"
			;;
		f)
			FILTER=$OPTARG
			echo "Grep filter is $FILTER"
			;;
		x)
			EXTRACT=$OPTARG
			echo "Extract command is $EXTRACT"
			;;
		s)
			EXTRACT=$SSN_EXTRACT
			echo "Extracting SSNs"
			;;
		h)
			usage
			exit
			;;
	esac
done

# make sure GIT_DIR is set
if [ -z $GIT_DIR ]; then
	echo "-g is required"
	usage
	exit 
fi

# make sure GIT_DIR is a dir
if [ -d $GIT_DIR ]; then
	cd $GIT_DIR
else
	echo "$GIT_DIR is not a directory"
	exit
fi

# prepare working dir
if [ -d $WORK ]; then
	rm $WORK/commit_hashes
	rm $WORK/tree_hashes
else
	echo 'Making work directory $WORK'
	mkdir $WORK
fi

# get the commit hashes that have $filter
git log --pretty=tformat:"%H" -- $FILTER > $WORK/commit_hashes

# get the trees
while read line; do
	if [ -z "$FILTER" ]; then
		EXPAND_FILTER=
	else
		EXPAND_FILTER="| grep $FILTER"
	fi
	git cat-file -p $line^{tree} ${EXPAND_FILTER} | \
		cut -d " " -f 3 | cut -d "	" -f 1  >> $WORK/tree_hashes
done < $WORK/commit_hashes
	
# iterate through trees looking for blobs
while read line; do
	# walk tree with depth 0
	walk_tree $line
done < $WORK/tree_hashes

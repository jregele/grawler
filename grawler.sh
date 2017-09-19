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
COMMITS=false
OBJECT_HASH=
WALK_PACK=false
RESUME=false

SCRIPT_DIR=`pwd -P`


usage() {
	echo "usage: $program_name [-hCPr] [-g dir] [-w dir] [-f filter] [-x regex] [-W hash]"
	echo "	-g 	git directory"
	echo "	-w 	working directory"
	echo "	-f 	filter for git log"
	echo "	-x 	extract: (p) Password, (k) Keys, (c) Secrets, (s) SSN"
	echo "	-h 	print this cruft"
	echo "	-C 	print commit hashes"
	echo "	-W 	which commit has hash object"
	echo " 	-P 	walk pack file"
	echo " 	-r 	resume (don't kill tree_file"
	echo "Only one type of extract may be performed at a time"
}

which_commit() {
	obj_name="$1"
	shift
	git log "$@" --pretty=format:'%T %H %s' \
	| while read tree commit subject ; do
	    if git ls-tree -r $tree | grep -q "$obj_name" ; then
	        echo $tree $commit "$subject"
	    fi
	done
}

dump_blob() {
	# the reason we have to do all this very explicit branching is because if we start evaling,
	# then the $0 in the awk match statement evals to the global $0, ie the name of the script
	# but to make things more flexible started using python extractor.py instead of awk
	# hopefully we can condense this then
	commit_hash=$1
	if [ "$EXTRACT" == "s" ]; then
		if [ "$COMMITS" = true ]; then
			git cat-file -p $1 | egrep '[0-9]{3}-[0-9]{2}-[0-9]{4}' | python ${SCRIPT_DIR}/extractor.py --ssn -H $commit_hash
		else
			# git cat-file -p $1 | egrep '[0-9]{3}-[0-9]{2}-[0-9]{4}' | awk 'match($0, /[0-9]{3}-[0-9]{2}-[0-9]{4}/) { print substr( $0, RSTART, RLENGTH)}'
			git cat-file -p $1 | egrep '[0-9]{3}-[0-9]{2}-[0-9]{4}' | python ${SCRIPT_DIR}/extractor.py --ssn
				# awk 'match($0, /[0-9]{3}-[0-9]{2}-[0-9]{4}/) { print substr( $0, RSTART, RLENGTH)}'
		fi
	elif [ "$EXTRACT" == "p" ]; then
		git cat-file -p $1 | egrep -i 'password|pw' | python ${SCRIPT_DIR}/extractor.py --password -H $commit_hash
	elif [ "$EXTRACT" == "k" ]; then
		git cat-file -p $1 | egrep -i 'key' | python ${SCRIPT_DIR}/extractor.py --key -H $commit_hash
	elif [ "$EXTRACT" == "c" ]; then
		git cat-file -p $1 | egrep -i 'secret' | python ${SCRIPT_DIR}/extractor.py --secret -H $commit_hash
	fi
}

walk_tree() {
	# params 
	# hash = $1
	type=$(git cat-file -t $1)
	if [ "$type" = "blob" ]; then
		dump_blob $1
	elif [ "$type" = "commit" ]; then
		tree=$(git cat-file -p $1 | grep tree | cut -d " " -f 2)
		walk_tree $tree
	else
		# git cat-file -p $2 | cut -d " " -f 3 | cut -d "	" -f 1
		subtrees=$(git cat-file -p $1 | cut -d " " -f 3 | cut -d "	" -f 1)
		for tree in $subtrees; do
			walk_tree $tree
		done
	fi
}

while getopts "g:w:f:x:hCWPr" opt; do
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
		C)
			COMMITS=true
			echo "Printing commit hashes"
			;;
		W)
			echo "This option is currently disabled because bash is stupid"
			exit
			OBJECT_HASH=$OPTARG
			;;
		P)
			WALK_PACK=true
			echo "Walking pack file"
			;;
		r)
			RESUME=true
			echo "Resuming"
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

# are we searching for a which commit?
if [ -n "${OBJECT_HASH}" ]; then
	which_commit $OBJECT_HASH
	exit
fi



# prepare working dir
if [ -d $WORK ]; then
	rm $WORK/commit_hashes
	if [[ "$RESUME" -ne true ]]; then
		rm $WORK/tree_hashes
	fi
else
	echo 'Making work directory $WORK'
	mkdir $WORK
fi

# if not resuming, get the trees
if [[ $RESUME -eq false ]]; then

	if [[ $WALK_PACK = true ]]; then
		echo "Walking Pack"
		echo "This may take awhile...."
		for f in `ls .git/objects/pack/pack-*.pack`
		do
			echo $f
			git verify-pack -v $f | egrep '(commit|tree|blob)' | cut -d " " -f 1 >> $WORK/commit_hashes
		done
		
	else
		echo "Crawling git-log using $FILTER"
		# get the commit hashes that have $filter
		git log --pretty=tformat:"%H" -- $FILTER > $WORK/commit_hashes
	fi


	while read line; do
		# if [[ "$WALK_PACK" -eq true ]]; then
		# 	# we already cut it down so just echo the hash over
		# 	git cat-file -p $line | cut -d " " 
		# 	echo "$line" >> $WORK/tree_hashes
		if [ -z "$FILTER" ]; then
			git cat-file -p $line^{tree} | \
				cut -d " " -f 3 | cut -d "	" -f 1  >> $WORK/tree_hashes
		else
			git cat-file -p $line^{tree} | grep $FILTER | \
				cut -d " " -f 3 | cut -d "	" -f 1  >> $WORK/tree_hashes
		fi	
	done < $WORK/commit_hashes
fi

# iterate through trees looking for blobs
while read line; do
	# walk tree with depth 0
	walk_tree $line
done < $WORK/tree_hashes

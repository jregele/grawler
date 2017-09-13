#!/bin/bash

cd ~/git/casepeer


export WORK=~/Desktop/casepeer/work

pprint() {
	#params
 	str=$1
 	num=$(($2))
 	v=$(printf "%-${num}s" "$str")
 	echo "${v// /*}"
}

walk_tree() {
	# params 
	# hash = $1
	type=$(git cat-file -t $1)
	if [ "$type" = "blob" ]; then
		# echo $2
		git cat-file -p $1 | egrep '[0-9]{3}-[0-9]{2}-[0-9]{4}' | awk 'match($0, /[0-9]{3}-[0-9]{2}-[0-9]{4}/) { print substr( $0, RSTART, RLENGTH)}'
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

while getopts "g:w:f:x:" opt; do
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
			echo "Extract command is"


if [ -d $WORK ]; then
	echo 'Work directory already exists'
	rm $WORK/commit_hashes
	rm $WORK/tree_hashes
else
	echo 'Making work directory'
	mkdir $WORK
fi

# get the commit hashes that have new_data_migrations
git log --pretty=tformat:"%H" -- new_data_migrations > $WORK/commit_hashes

# get the trees
while read line; do
	git cat-file -p $line^{tree} | grep new_data_migrations | \
		cut -d " " -f 3 | cut -d "	" -f 1  >> $WORK/tree_hashes
done < $WORK/commit_hashes
	
# iterate through trees looking for blobs
while read line; do
	# walk tree with depth 0
	walk_tree $line
done < $WORK/tree_hashes
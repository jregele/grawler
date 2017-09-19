# Grawler

grawler.sh recursively walks object trees in a git database searching for "deleted" passwords, secrets, keys, and other sensitive information. It runs using git plumbing commands and can walk either from refs accumulated from git log, or from walking git pack files.

### Usage

```bash
usage: ./grawler.sh [-hCPr] [-g dir] [-w dir] [-f filter] [-x regex] [-W hash]
	-g 	git directory
	-w 	working directory
	-f 	filter for git log
	-x 	extract: (p) Password, (k) Keys, (c) Secrets, (s) SSN
	-h 	print this cruft
	-C 	print commit hashes
	-W 	which commit has hash object
 	-P 	walk pack file
 	-r 	resume (don't kill tree_file)
```

A git directory is required (-g). Filtering (-f) assists if you have an idea of where to start in the git history, but will be ignored if walking pack files (-P). Nothing useful will happen if an extract (-x) option is not set. Currently supported are passwords (p), keys (k), secrets (c), and Social Security Numbers (s). The extraction for p, k, and c will print the matched regex until the end of the line, in hopes of exposing the values. For extract option s, only the SSN regex match will be output.

### Example

Extract passwords and print commit hashes they are in

```bash
./grawler.sh -C -g ~/myrepo -x p
```

You can always investigate more using 

```bash
git cat-file -p commit hash
```


### Caveat

Because of some bugs using awk for extraction, extractor.py is used instead. This needs to be in the same directory as grawler.sh. Killing the program may require a few attempts because python gets run alot once the walk gets going.

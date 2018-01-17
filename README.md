# Grawler
##### Released at ShmooCon 2018

grawler recursively walks object trees in a git database searching for "deleted" passwords, secrets, keys, and other sensitive information. It runs using git plumbing commands and can walk from refs accumulated from git log, git pack files, or the file system.

### Usage

```bash
usage: grawler [-h] [-m mode] [-x extractor] [-f filter] [-R regex] [-g dir] [-w dir] "
      -m  Mode: (git) git log, (pack) pack files, (fs) filesystem"
      -x  extractor: (p) Password, (k) Keys, (c) Secrets, (s) SSN, (r) Regex"
      -f  filter for git log"
      -R  regex for custom extractor (required for -x r)
      -g  git directory (optional)"
      -w  working directory (optional)"
      -h  print this cruft"
    Only one extractor may be performed at a time"
```

Grawler will attempt run in the current directory, if it is a git repo. -g can be used to specify a different repo. 

Modes, specified with the -m flag, use git log, pack files, or walk the filesystem. Each can find secrets the others may miss. For instance, fs mode can detect secrets after git history has been rewritten, if the refs have not been deleted. Pack mode will find secrets stored in pack files that disappeared from the objects/ directory.

Nothing useful will happen if an extractor (-x flag) is not set. Currently supported are passwords (p), keys (k), secrets (c), and Social Security Numbers (s). The extraction for p, k, and c will print the matched regex until the end of the line, in hopes of exposing the values. For extract option s, only the SSN regex match will be output. Custom extractors are supported using regular expressions. Use -x r, and then set the -R <your regex here> flag.

Extractors are not magical. They are built using grep and regex filters so if a password variable is not set with a variant of the word password, grawler will not find it unless you use a custom extractor. To search for high entropy strings in, see [truffleHog](https://github.com/dxa4481/truffleHog). 

Filtering (-f) assists if you have an idea of where to start in the git history, but will be ignored in pack and fs modes. 

### Install

```bash
./install.sh
```

### Example

Extract passwords in git mode

```bash
grawler -x p -m git
```

Extract encryption keys using pack mode

```bash
grawler -x k -m pack
```

Extract lines with "secret" in fs mode in another repo with local working directory. This will create tree_hash and commit_hash files in the current directory. 

```bash
grawler -x s -m fs -g ~/myrepo -w .
```

You can always investigate more using 

```bash
git cat-file -p <commit hash>
```


### Caveats

Because of some bugs using awk for extraction, grawler_extractor.py is used instead. This needs to be in the same directory as grawler.sh. Killing the program may require a few attempts because python gets run alot once the walk gets going.

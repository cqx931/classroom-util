#!/bin/bash

# NOTE: needs to add pagination support: https://developer.github.com/guides/getting-started/#pagination

assignment="imc-assignment-9"

#
# finds all private repos for $assignment not including 'test' in the name
#
# usage: $ ./fetch-students.sh [username] [password] (will prompt if password is not supplied)
#
# rather than typing a password on the command-line, save to file only readable by yourself, then do:
#      $ ./fetch-students.sh username `cat passwordfile`
#

in=repos.js
out=students.txt
usr=${1:-$(whoami)}
pass=${2}

if [ -z "$pass" ]; 
then
  curl -u ${usr} "https://api.github.com/orgs/SchoolOfCreativeMedia/repos?type=private&per_page=100" > ${in}
else
  curl -u ${usr}:${pass}  "https://api.github.com/orgs/SchoolOfCreativeMedia/repos?type=private&per_page=100" > ${in}
fi

cat ${in} | jq '.[] | .name' | egrep  ${assignment} | grep -v test | sed 's/"//g' #> ${out}

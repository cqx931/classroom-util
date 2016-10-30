#!/bin/bash

# NOTE: needs to add pagination support: https://developer.github.com/guides/getting-started/#pagination

orgname="SchoolOfCreativeMedia"
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
url="https://api.github.com/orgs/SchoolOfCreativeMedia/repos?type=private&per_page=100&page="
START=1
END=2

for i in $(eval echo "{$START..$END}"); do
if [ -z "$pass" ]; 
then
  curl -u ${usr} ${url}$i 
else
  curl -u ${usr}:${pass} ${url}$i 
fi
done > ${in}

cat ${in} | jq '.[] | .name' | egrep  ${assignment} | grep -v test | sed 's/"//g' > tmp1.txt

sed "s/^${assignment}-//" tmp1.txt > tmp2.txt
sort tmp2.txt -o tmp1.txt
echo ${orgname} | cat - tmp1.txt > ${out}

head ${out}



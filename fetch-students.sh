#!/bin/bash

# NOTE: needs to add pagination support: https://developer.github.com/guides/getting-started/#pagination

assignment="imc-assignment-9"

#
# finds all private repos for $assignment not including 'test' in the name
#
# usage: $ ./fetch-students.sh [username]
#

in=repos.js
out=students.txt
usr=${1:-$(whoami)}

curl -u ${usr}  https://api.github.com/orgs/SchoolOfCreativeMedia/repos?type=private > ${in}
cat ${in} | jq '.[] | .name' | egrep  ${assignment} | grep -v test | sed 's/"//g' #> ${out}

#!/bin/bash

file=repos.js
usr=${1:-$(whoami)}
curl  -u ${usr}  https://api.github.com/orgs/SchoolOfCreativeMedia/repos?type=private > ${file}
cat ${file} | jq '.[] | .name'

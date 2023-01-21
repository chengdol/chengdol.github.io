#!/usr/bin/env bash
# Note that some commands have different options on MacOS
#
# Author:       chengdol
# Description:  Generate list of blogs for reviewing.
# Usage:
#   --local: generate local service URL
#
###################################################################
#set -ueo pipefail
#set -x

# days to trace back, modify here
declare -i day=60
declare -a sha_list=($(git rev-list HEAD --since=${day}days))
#declare -p sha_list

URL_PREFIX="https://chengdol.github.io" #/2021/01/02/book-infra-as-code/
if [[ "${1##--}" == "local" ]]; then
  URL_PREFIX="http://localhost:4000"
fi
REVIEW_FILE="./_posts/review-list.md"

# content
cat <<_EOF > ${REVIEW_FILE}
---
title: Blog Review List
date: {{ DATE }}
---

**AUTO GENERATION**
There are **{{ NUM }}** blogs written or updated in last **{{ DAY }}** days: 

_EOF

files=""
for((i=1;i<${#sha_list[@]};i++))
do 
  # only count .md file
  # excludes itself and todo list
  tmp=$(git diff --name-only --diff-filter=ACMR ${sha_list[i]} ${sha_list[i-1]} \
          | grep -E ".+\.md" \
          | grep -v -E "review-list\.md" \
          | grep -v -E "inprogress\.md" \
          || echo "")
  files="$tmp $files"
done

declare -a file_list=($(echo $files | tr " " "\n" | sort | uniq))
#declare -p file_list
declare -i cnt=${#file_list[@]}
for ((i=0;i<${#file_list[@]};i++))
do
  # sometimes I changed the file name, so original one non-exist
  if ! [[ -f ${file_list[i]} ]]; then
    let cnt--
    continue
  fi
  # retrieve specified line
  title=$(sed -n -e 2p ${file_list[i]})

  date=$(sed -n -e 3p ${file_list[i]})
  date=${date##"date: "}
  date=${date%%[[:space:]]*}
  date=${date//-/\/}

  file_name=${file_list[i]##"_posts/"}
  file_name=${file_name%".md"}
  echo "- [${title##"title: "}](${URL_PREFIX}/${date}/${file_name})" >> ${REVIEW_FILE}
done

sed -i "" \
    -e "s#{{ DATE }}#$(date '+%Y-%m-%d %H:%M:%S')#g; s#{{ NUM }}#${cnt}#g; s#{{ DAY }}#${day}#g" \
    ${REVIEW_FILE}

#!/bin/bash

r=$(./sel | cat -n | tee /tmp/termidash |sed -e 's/|/   /g'  | fzf)
num=$(echo -n $r | awk '{print $1}')

echo $num
egrep "^\s*$num\s" /tmp/termidash | awk -F'|' '{print $1, $NF}' | xargs ./open-it

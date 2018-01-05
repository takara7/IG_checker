#!/bin/bash

set -eu

LOGDIR=$(dirname $0)/log
CURRENT=${LOGDIR}/current.log

cd $LOGDIR
new_name=$(date -d '1 month ago' +%Y-%m).log
mv $CURRENT $new_name
touch $CURRENT

to_be_compressed=$(date -d '2 month ago' +%Y-%m).log
[ -e $to_be_compressed ] && gzip -q $to_be_compressed

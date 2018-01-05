#!/bin/bash -l

set -eu
cd $(dirname $0)

LOG=./log/current.log
# ネットワーク系のエラーはしばらくすると治ることが多い（そもそもネットワークが
# ダメならメールも届かない）ので、ログには残すが出力（cronのメールで送信）しない
IGNORED_ERROR="SocketError\|Errno::ENETUNREACH\|OpenURI::HTTPError\|Net::OpenTimeout"

./ig_checker.rb 2>&1 >> $LOG | tee -a $LOG | grep -v ^$'\t' | grep -v $IGNORED_ERROR

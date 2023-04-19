#!/usr/bin/env sh
set -eu

session=$1
folder=$2

# otherwise commands will run in current dir
cd $folder

save="${folder}/.session.vim"

has_session(){
  [ -e "$save" -a -s "$save" ]
}

cmd=$(has_session && echo "-S ${save}" || echo "-c 'Obsession ${save}'")
tmux send-keys -t $session:1 "vim ${cmd}" Enter
tmux neww -d -n workspace  -t $session:2
tmux neww -d -n compiler  -t $session:8

# vim:set ft=sh:

#!/usr/bin/env bash

###########################
# This script bootstrap the .dotfiles in a system without git
###########################

# check if there is a clone of .dotfiles already running
if [[ ! -e ~/.dotfiles ]]; then
  # keeps system alive
  caffeinate -i -d &
  caff_pid=$!

  # install command line tools so we have git
  # loops while we don't have the tools installed
  while true; do
    xcode-select --install > /dev/null 2>&1
    sleep 5
    xcode-select -p > /dev/null 2>&1
    [ $? == 2 ] || break
  done
  # clone repo
  git clone --recurse-submodules https://github.com/jfloff/.dotfiles ~/.dotfiles > /dev/null 2>&1
  # kills caffeinate, theres already one running inside install.sh
  kill -INT $caff_pid
fi

# already exists run install script
pushd ~/.dotfiles/ > /dev/null 2>&1
# set input from the terminal
./install.sh </dev/tty
popd > /dev/null 2>&1

#!/usr/bin/env bash

###########################
# This script installs the dotfiles and runs all other system configuration scripts
# @author Adam Eivy
# @contributor João Loff
###########################
DEFAULT_EMAIL="jfloff@gmail.com"
DEFAULT_GITHUBUSER="jfloff"


# include my library helpers for colorized echo and require_brew, etc
source ./lib.sh
# sourcing shellvars so we can get tools specific pre-loaded settings
source ~/.shellvars

# make a backup directory for overwritten dotfiles
if [[ ! -e ~/.dotfiles_backup ]]; then
    mkdir ~/.dotfiles_backup
fi

################################################
bot "Hi. I'm here to make your OSX a better system!"
################################################


################################################
bot "Setting up personal info, so you don't check in files to github as João Loff :)"
################################################

################################################
# Full name
################################################
fullname=`osascript -e "long user name of (system info)"`
if [[ -n "$fullname" ]];then
  lastname=$(echo $fullname | awk '{print $2}');
  firstname=$(echo $fullname | awk '{print $1}');
fi

fullname=`dscl . -read /Users/$(whoami)  | awk 'f {print; exit} /RealName/ {f=1}' | xargs`
if [[ -z $firstname ]]; then
  firstname=$(echo $fullname | awk '{print $1}');
fi
if [[ -z $lastname ]]; then
  lastname=$(echo $fullname | awk '{print $2}');
fi

if [[ ! "$firstname" ]];then
  response='n'
else
  question "Is this your full name '$COL_YELLOW$firstname $lastname$COL_RESET'? [Y|n]" response
fi

if [[ $response =~ ^(no|n|N) ]];then
  question "What is your first name? " firstname
  question "What is your last name? " lastname
fi
fullname="$firstname $lastname"

running "Full name set to '$COL_YELLOW$fullname$COL_RESET'";ok

################################################
# Email
################################################
email=`dscl . -read /Users/$(whoami) | grep RecordName | awk '{print $3}'`
if [[ ! $email ]];then
  response='n'
else
  question "Is this your email '$COL_YELLOW$email$COL_RESET'? [Y|n]" response
fi

if [[ $response =~ ^(no|n|N) ]];then
  question "What is your email then? [$DEFAULT_EMAIL] " email
  if [[ ! $email ]];then
    email=$DEFAULT_EMAIL
  fi
fi

running "Email set to '$COL_YELLOW$fullname$COL_RESET'";ok

################################################
# github username
################################################
githubuser=`awk '/user = /{ print $3 }' .gitconfig`
if [[ ! $githubuser ]];then
  response='n'
else
  question "Is this your github username '$COL_YELLOW$githubuser$COL_RESET'? [Y|n]" response
fi

if [[ $response =~ ^(no|n|N) ]];then
  question "What is your github username  then? [$DEFAULT_GITHUBUSER] " githubuser
  if [[ ! $githubuser ]];then
    githubuser=$DEFAULT_GITHUBUSER
  fi
fi
running "Email set to '$COL_YELLOW$fullname$COL_RESET'";ok

botdone

################################################
bot "Cheking sudo"
################################################
promptSudo

################################################
# check if user wants sudo passwordless
################################################
if sudo grep -q "# %wheel\tALL=(ALL) NOPASSWD: ALL" "/etc/sudoers"; then
  question "Do you want me to setup this machine to allow you to run sudo without a password?\n
      More infomation here: http://wiki.summercode.com/sudo_without_a_password_in_mac_os_x \n
      [y|N]" response

  if [[ $response =~ (yes|y|Y) ]];then
      sed --version
      if [[ $? == 0 ]];then
          sudo sed -i 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers
      else
          sudo sed -i '' 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers
      fi
      sudo dscl . append /Groups/wheel GroupMembership $(whoami)
      running "You can now run sudo commands without password!"
  fi
fi
ok

botdone

################################################
bot "Setting up >crontab nightly jobs<"
################################################
running "symlinking shell files"; filler
pushd ~ > /dev/null 2>&1
symlinkifne .crontab
popd > /dev/null 2>&1

botdone

################################################
bot "Setting up >ZSH<"
################################################

running "changing your login shell to zsh"
echo $0 | grep zsh > /dev/null 2>&1 | true
if [[ ${PIPESTATUS[0]} != 0 ]]; then
  chsh -s $(which zsh)
fi
ok

running "symlinking shell files"; filler
pushd ~ > /dev/null 2>&1
# common to all shells
symlinkifne .profile
symlinkifne .shellaliases
symlinkifne .shellfn
symlinkifne .shellpaths
symlinkifne .shellvars
# zsh shell
symlinkifne .zlogout
symlinkifne .zprofile
symlinkifne .zshenv
symlinkifne .zshrc
popd > /dev/null 2>&1

ok; botdone

################################################
# homebrew
################################################
source ./brew.sh

################################################
# osx
################################################
source ./osx.sh

################################################
# brew-cask
################################################
source ./casks.sh

################################################
# "extras"
################################################
source ./extras.sh

################################################
bot "Cleaning up the mess ..."
################################################
# Remove outdated versions from the cellar
running "Cleaning up homebrew cache..."
brew cleanup > /dev/null 2>&1
brew cask cleanup > /dev/null 2>&1
ok

question "Can I clean up downloads directory? [y|N]" response
if [[ $response =~ ^(yes|y|Y) ]];then
  rm -rf ./downloads
fi
ok

running "Note that some of these changes require a logout/restart to take effect.\n
Killing affected applications (so they can reboot)...."
for app in "Activity Monitor" "Address Book" "Calendar" "Contacts" "cfprefsd" \
  "Dock" "Finder" "Mail" "Messages" "Safari" "SystemUIServer" \
  "iCal" "Terminal" "Transmission" "Atom" "Alfred"; do
  killall "${app}" > /dev/null 2>&1
done

botdone

###############################################################################
bot "Unfortunately I can't setup everything :( Heres a list of things you need to do manually"
###############################################################################
item 1 "Installing from App Store:"
item 2 "Keynote"
item 2 "Numbers"
item 2 "Pages"
filler
item 1 "Set iCloud settings:"
item 2 "Disable Safari and Mail sync"
item 2 "Sign in for Facebook, Twitter, Linkedin, Google (Only select contacts)"
filler
item 1 "Set Dropbox configuration:"
item 2 "Show desktop notifications"
item 2 "Start dropbox on system startup"
item 2 "Selective Sync folders"
item 2 "Do not enable camera uploads"
item 2 "Share screenshots using Dropbox"
item 2 "Enable LAN sync"
filler
item 1 "Set Alfred configuration:"
item 2 "General: set hotkey to CMD-Space"
item 2 "Appearance: OSX Yosemite Dark"
filler
item 1 "Set AppTrap configuration:"
item 2 "Start on login"
filler
item 1 "Set Mendeley configuration:"
item 2 "Login with account"
item 2 "File Organizer > Organize my files: ~/Dropbox/PhD Loff/rw"
item 2 "File Organizer > Sort files into subfolders > Folder path: Year"
item 2 "File Organizer > Rename document files > Filename: Author Year Title"
filler
item 1 "Set Texpad configuration:"
item 2 "Import configuration file in ~/.dotfile/configs/texpad.settings.json"
filler

botdone

################################################
bot "Woot! All done."
################################################

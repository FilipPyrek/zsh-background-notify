#!/usr/bin/env zsh


## setup ##

[[ -o interactive ]] || return #interactive only!
zmodload zsh/datetime || { print "can't load zsh/datetime"; return } # faster than date()
autoload -Uz add-zsh-hook || { print "can't add zsh hook!"; return }

(( ${+bgnotify_threshold} )) || bgnotify_threshold=5 #default 10 seconds

bgnotify_timestamp=$EPOCHSECONDS



## definitions ##

currentWindowId () {
  if hash notify-send 2>/dev/null; then #ubuntu!
    xprop -root | awk '/NET_ACTIVE_WINDOW/ { print $5; exit }'
  elif hash osascript 2>/dev/null; then #osx
    osascript -e 'tell application (path to frontmost application as text) to id of front window' 2&> /dev/null
  fi
}

bgnotify () {
  if hash notify-send 2>/dev/null; then #ubuntu!
    notify-send $1 $2
  elif hash terminal-notifier 2>/dev/null; then #osx
    terminal-notifier -message $2 -title $1
  elif hash growlnotify 2>/dev/null; then #osx growl
    growlnotify -m $1 $2
  fi
}

bgnotify_begin() {
  bgnotify_timestamp=$EPOCHSECONDS
  bgnotify_lastcmd=$1
  bgnotify_windowid=$(currentWindowId)
}

bgnotify_end() {
  didexit=$?
  past_threshold=$(( $EPOCHSECONDS - $bgnotify_timestamp >= $bgnotify_threshold ))
  is_background=$([[ "$(currentWindowId)" -eq "$bgnotify_windowid" ]])
  if (( bgnotify_timestamp > 0 )) && (( past_threshold )) && (( ! is_background )); then
    print -n "\a"
    bgnotify $([ $didexit -ne 0 ] && echo '#fail' || echo '#win!') "$bgnotify_lastcmd"
  fi
  bgnotify_timestamp=0 #reset it to 0!
}

add-zsh-hook preexec bgnotify_begin
add-zsh-hook precmd bgnotify_end

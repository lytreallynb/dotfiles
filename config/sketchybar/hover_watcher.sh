#!/bin/bash

# Polls mouse Y position; when cursor is within HIDE_ZONE px of the top,
# hides sketchybar so the macOS menu bar can show through.

HIDE_ZONE=35
INTERVAL=0.1
LAST=""

while true; do
  Y=$(/opt/homebrew/bin/cliclick p 2>/dev/null | awk -F, '{print $2}')
  if [ -z "$Y" ]; then
    sleep "$INTERVAL"
    continue
  fi

  if [ "$Y" -lt "$HIDE_ZONE" ]; then
    STATE=on
  else
    STATE=off
  fi

  if [ "$STATE" != "$LAST" ]; then
    /opt/homebrew/bin/sketchybar --bar hidden=$STATE >/dev/null 2>&1
    LAST=$STATE
  fi

  sleep "$INTERVAL"
done

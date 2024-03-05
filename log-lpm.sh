#!/bin/bash

tmpfile=$(mktemp)
start=$(date +%s)

update_metrics() {
  local previous_lines=0
  local previous_timestamp=$start
  while true; do
    local now=$(date +%s)
    local lines=$(wc -l < "$tmpfile")
    local seconds=$((now - start))
    local interval=$((now - previous_timestamp))
    if [ "$interval" -gt 0 ]; then
      local new_lines=$((lines - previous_lines))
      local lpm=$(echo "$new_lines $interval" | awk '{print (60 * $1 / $2)}')
      local lps=$(echo "$new_lines $interval" | awk '{print ($1 / $2)}')
      echo -ne "\033[1;32mLines per minute:\033[0m $lpm, \033[1;32mLines per second:\033[0m $lps, \033[1;32mRunning time:\033[0m $seconds seconds\r"
      previous_lines=$lines
      previous_timestamp=$now
    fi
    sleep 1
  done
}

cleanup() {
  echo -ne "\r\033[K"

  kill "$bg_pid" 2>/dev/null
  wait "$bg_pid" 2>/dev/null
  
  if [ -f "$tmpfile" ]; then
    local now=$(date +%s)
    local total_runtime=$((now - start))
    local total_logs=$(wc -l < "$tmpfile")
    local lpm=0
    local lps=0
    if [ "$total_runtime" -gt 0 ]; then
      lpm=$(echo "$total_logs $total_runtime" | awk '{print (60 * $1 / $2)}')
      lps=$(echo "$total_logs $total_runtime" | awk '{print ($1 / $2)}')
    fi
    local error_count=$(grep -c "ERROR" "$tmpfile")

    echo -e "\033[1;33mExiting...\033[0m"
    echo -e "\033[1;32mTotal runtime:\033[0m ${total_runtime} seconds"
    echo -e "\033[1;32mTotal logs:\033[0m ${total_logs}"
    echo -e "\033[1;32mLines per minute:\033[0m ${lpm}"
    echo -e "\033[1;32mLines per second:\033[0m ${lps}"
    echo -e "\033[1;32mError count:\033[0m ${error_count}"
    
    rm -f "$tmpfile"
  fi
}

trap 'cleanup' SIGINT SIGTERM EXIT

update_metrics &
bg_pid=$!

while IFS= read -r line; do
  echo "$line" >> "$tmpfile"
done

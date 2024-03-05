#!/bin/bash
tmpfile=$(mktemp)
cleanup() {
  end=$(date +%s)
  lines=$(wc -l < "$tmpfile")
  lpm=$((60*lines/(end-start)))
  echo "Lines per minute: $lpm"
  rm -f "$tmpfile"
}
trap cleanup EXIT
start=$(date +%s)
while IFS= read -r line; do
  echo "$line" >> "$tmpfile"
done
cleanup

#!/bin/bash

# USB read/write speed test with logging and cancel handling
# Usage: ./test-read-write.sh /Volumes/YOUR_USB_DRIVE

set -euo pipefail

DRIVE="${1:-}"
FILE="testfile.dat"
BS="1m"
COUNT="1024"  # 1GB
LOG="/tmp/usb-speed-test.log"

if [[ -z "$DRIVE" || ! -d "$DRIVE" ]]; then
  echo "Usage: $0 /Volumes/YOUR_USB_DRIVE" >&2
  exit 1
fi

trap 'echo "Canceled. Cleaning up..." | tee -a "$LOG"; rm -f "$DRIVE/$FILE"; exit 130' SIGINT SIGTERM

log() {
  echo "[$(date +'%H:%M:%S')] $*" | tee -a "$LOG"
}

write_test() {
  sync
  log "Writing $COUNT blocks of $BS..."
  dd if=/dev/zero of="$DRIVE/$FILE" bs=$BS count=$COUNT conv=fsync status=none
  log "Write complete."
}

read_test() {
  sync
  log "Reading test file..."
  dd if="$DRIVE/$FILE" of=/dev/null bs=$BS status=none
  log "Read complete."
}

log "Starting USB speed test on $DRIVE"
t0=$(date +%s)
write_test
t1=$(date +%s)

t2=$(date +%s)
read_test
t3=$(date +%s)

wt=$((t1 - t0))
rt=$((t3 - t2))

log "Results:"
printf "write: %4d MB/s\n" $((1024 / wt)) | tee -a "$LOG"
printf " read: %4d MB/s\n" $((1024 / rt)) | tee -a "$LOG"

rm -f "$DRIVE/$FILE"
log "Temporary file removed. Done."
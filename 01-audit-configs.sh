#!/bin/bash

# cats out a bunch of files to an output file
# useful for auditing configs

INPUTFILES='''one
file
per
line'''

OUTPUTFILE="output.txt"
touch $OUTPUT_FILE

for i in $INPUTFILES;
do
  echo "-------" >> $OUTPUTFILE
  if [ -f $i ]; then
    echo '###'$i >> $OUTPUTFILE
    echo "" >> $OUTPUTFILE
    cat $i >> $OUTPUTFILE
  fi
done

#!/bin/bash -e
export LC_ALL="C"

if [ -z "$1" ]
then
    echo "Dumpfile password extractor v.1.0"
    echo "Usage: extractpaswd source_file
        extractpaswd source_file <target_directory>";
    exit 1;
fi

if [ ! -f "$1" ]
then
    echo "Given input is not a regular file"
    exit 1;
fi

if [ "$2" ] && [ ! -d "$2" ]
then
    echo "Given path is not a valid directory"
    exit 1;
fi

INFILE="$1"
INFILENAME=$(basename "$INFILE")
INFILEDIRNAME=$(dirname "$INFILE")
TARGETDIR=${2:-"$INFILEDIRNAME"}"/"
OUTFILE="$TARGETDIR${INFILENAME%%.*}-out.txt"
REMAINSFILE="$TARGETDIR${INFILENAME%%.*}-out-remains.txt"
WEAKFILE="$TARGETDIR${INFILENAME%%.*}-out-weak-"
SEPARATORS=( "\|" ":" "\;" )

if hash pv 2>/dev/null; then
   COMMAND="pv";
 else
   echo "Without 'pv' you will not be able to see the progress.
You can install it with homebrew - 'brew install pv' if you are on macOS,
or 'sudo apt-get install pv' on Debian/Ubuntu.

For now we're gonna use 'cat' instead.";
  COMMAND="cat";
fi

if [ "$1" == "-debug" ] || [ "$2" == "-debug" ] || [ "$3" == "-debug" ]; then
  echo "###########";
  locale
  echo "INFILE: $INFILE";
  echo "OUTFILE: $OUTFILE";
  echo "INFILENAME: $INFILENAME";
  echo "INFILEDIRNAME: $INFILEDIRNAME";
  echo "TARGETDIR: $TARGETDIR";
  echo "REMAINSFILE: $REMAINSFILE";
  echo "WEAKFILE: $WEAKFILE";
  echo "${SEPARATORS[*]}";
  echo "$($COMMAND -h)";
  echo "###########";
fi

echo "[$(date '+%H:%M:%S')] Starting parsing file '$INFILE'"
#extract main 3 groups of passwords
# for i in "${SEPARATORS[@]}"; do
#     RANGE="{1}"
#     echo "[$(date '+%H:%M:%S')] Parsing lines with '${i##\\}' separator"
#
#     #special rule for weird formatting of yahoo emails with ":" separator
#     if [ $i == ":" ]; then
#         RANGE="{1,2}"
#     fi
#
#     #"$COMMAND" "$INFILE" | sed -En "s/^[-[:alnum:]\ \.\!\#\$\%\&\*\+\/\=\?\^\_\`\{\|\}\~]+@$RANGE[[:print:]]+$i//p" >> "$OUTFILE";
#
#     #build string for matching all SEPARATORS
#     SSEPARATORS+=$i"|"
# done
echo "[$(date '+%H:%M:%S')] Parsing lines with '${SEPARATORS[*]}' separators"
"$COMMAND" "$INFILE" | perl -ne 'print if s/([[:print:]]+@+[[:print:]]+[:])|([[:print:]]+@+[[:print:]]+[;])|([[:print:]]+@+[[:print:]]+[|])//g' > "$OUTFILE";
# "$COMMAND" "$INFILE" | sed -En 's/([[:print:]]+@+[[:print:]]+[:])|([[:print:]]+@+[[:print:]]+[;])|([[:print:]]+@+[[:print:]]+[|])//p' > "$OUTFILE";
# parallel -a "$INFILE" -k --block 100M --pipe-part --progress 'sed -En "s/([[:print:]]+@+[[:print:]]+[:])|([[:print:]]+@+[[:print:]]+[;])|([[:print:]]+@+[[:print:]]+[|])//p"' > "$OUTFILE";
# parallel -a "$INFILE" -k --block 100M --pipe-part --bar "perl -pe 's/([[:print:]]+@+[[:print:]]+[:])|([[:print:]]+@+[[:print:]]+[;])|([[:print:]]+@+[[:print:]]+[|])//'" > "$OUTFILE";
# exit
# echo ${SSEPARATORS%|};
# exit
#extract remaining lines for further proccessing
echo "[$(date '+%H:%M:%S')] Extracting remaining lines for further proccessing"
# $COMMAND "$INFILE" | grep -Ev "[-[:alnum:]\_\.]+[\.]*[-[:alnum:]\_\.]*@{1,2}[-[:alnum:]\_\.]*[${SSEPARATORS%|}]{1}" > "$REMAINSFILE"
# "$COMMAND" "$INFILE" | sed -En '/^[-[:alnum:]\ \.\!\#\$\%\&\*\+\/\=\?\^\_\`\{\|\}\~]+@{1,2}[[:print:]]+[${SSEPARATORS%|}]{1}/!p' > "$REMAINSFILE"
"$COMMAND" "$INFILE" | perl -ne 'print if not /([[:print:]]+@+[[:print:]]+[:])|([[:print:]]+@+[[:print:]]+[;])|([[:print:]]+@+[[:print:]]+[|])/' > "$REMAINSFILE"

#exit
#following secions extract flaky, weak patterns, possible crap
#
## reversed pattern "pass:email"
echo "[$(date '+%H:%M:%S')] Extracting reversed pattern 'pass:email'"
# "$COMMAND" "$REMAINSFILE" | grep -E ":[-[:alnum:]\_\.]+[\.]*[-[:alnum:]\_\.]*@[-[:alnum:]\_\.]*" | tee -a "$TARGETDIR""reversed.txt" | sed -E "s/:(.*)+//" > "$WEAKFILE""reversed-patt.txt"
"$COMMAND" "$REMAINSFILE" | perl -ne 'print if /([:][[:print:]]+@+[[:print:]]+)/' | tee -a "$TARGETDIR""tmp.txt" | perl -ne 'print if s/:(.*)+//' > "$WEAKFILE""reversed-patt.txt"
#
## email-ish pattern, allows illegal characters, missing parts
echo "[$(date '+%H:%M:%S')] Extracting weak candidates"
# "$COMMAND" "$REMAINSFILE" | grep -E "[[:print:]@{0}]*@{1}[[:print:]]*:" | tee -a "$TARGETDIR""reversed.txt" | sed -E 's/(.*):+//' > "$WEAKFILE""weak-cand.txt"
"$COMMAND" "$REMAINSFILE" | perl -ne 'print if /([[:print:]]+@+([:]))/' | tee -a "$TARGETDIR""tmp.txt" | perl -ne 'print if s/:(.*)+//' > "$WEAKFILE""weak-cand.txt"

echo "[$(date '+%H:%M:%S')] Preparing file with rejected candidates (for manual check)"
"$COMMAND" "$REMAINSFILE" | grep -vFf "$TARGETDIR""tmp.txt" >> "$REMAINSFILE"".manual-check"
echo "[$(date '+%H:%M:%S')] Cleaning up temporary files"
echo "[$(date '+%H:%M:%S')] ""$TARGETDIR""tmp.txt"
# rm "$TARGETDIR""reversed.txt"

echo "[$(date '+%H:%M:%S')] Finished extracting"

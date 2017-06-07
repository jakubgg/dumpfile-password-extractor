#!/bin/bash -Ce
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
You can install it with homebrew - 'brew install pv' if you are on macOS.
For now we're gonna use 'cat'.";
  COMMAND="cat";
fi

if [ "$1" == "-debug" ] || [ "$2" == "-debug" ] || [ "$3" == "-debug" ]; then
  echo "###########"
  locale
  echo "INFILE: "$INFILE;
  echo "OUTFILE: "$OUTFILE;
  echo "INFILENAME: "$INFILENAME
  echo "INFILEDIRNAME: "$INFILEDIRNAME
  echo "TARGETDIR: "$TARGETDIR
  echo "REMAINSFILE: "$REMAINSFILE
  echo "WEAKFILE: "$WEAKFILE
  echo "${SEPARATORS[*]}";
  echo "$($COMMAND -h)";
  echo "###########"
fi

echo "[$(date '+%H:%M:%S')] Starting parsing file '$INFILE'"
#extract main 3 groups of passwords
for i in "${SEPARATORS[@]}"; do
    RANGE="{1}"
    echo "[$(date '+%H:%M:%S')] Parsing lines with '${i##\\}' separator"

    #special rule for weird formatting of yahoo emails with ":" separator
    if [ $i == ":" ]; then
        RANGE="{1,2}"
    fi

    $COMMAND "$INFILE" | sed -En "s/^[-[:alnum:]\ \.\!\#\$\%\&\*\+\/\=\?\^\_\`\{\|\}\~]+@$RANGE[[:print:]]+$i//p" >> "$OUTFILE";

    #build string for matching all SEPARATORS
    SSEPARATORS+=$i"|"
done

# echo ${SSEPARATORS%|};
# exit
#extract remaining lines for further proccessing
echo "[$(date '+%H:%M:%S')] Extracting remaining lines for further proccessing"
$COMMAND "$INFILE" | grep -Ev "[-[:alnum:]\_\.]+[\.]*[-[:alnum:]\_\.]*@{1,2}[-[:alnum:]\_\.]*[${SSEPARATORS%|}]{1}" > "$REMAINSFILE"

#following secions extract flaky, weak patterns, possible crap
#
## reversed pattern "pass:email"
echo "[$(date '+%H:%M:%S')] Extracting reversed pattern 'pass:email'"
$COMMAND "$REMAINSFILE" | grep -E ":[-[:alnum:]\_\.]+[\.]*[-[:alnum:]\_\.]*@[-[:alnum:]\_\.]*" | tee -a "$TARGETDIR""reversed.txt" | sed -E "s/:(.*)+//" > "$WEAKFILE""reversed-patt.txt"
#
## email-ish pattern, allows illegal characters, missing parts
echo "[$(date '+%H:%M:%S')] Extracting weak candidates"
$COMMAND "$REMAINSFILE" | grep -E "[[:print:]@{0}]*@{1}[[:print:]]*:" | tee -a "$TARGETDIR""reversed.txt" | sed -E 's/(.*):+//' > "$WEAKFILE""weak-cand.txt"

echo "[$(date '+%H:%M:%S')] Preparing file with rejected candidates (for manual check)"
$COMMAND "$REMAINSFILE" | grep -vFf "$TARGETDIR""reversed.txt" >> "$REMAINSFILE"".manual-check"
echo "[$(date '+%H:%M:%S')] Cleaning up temporary files"
echo "[$(date '+%H:%M:%S')] ""$TARGETDIR""reversed.txt"
rm "$TARGETDIR""reversed.txt"

echo "[$(date '+%H:%M:%S')] Finished extracting"

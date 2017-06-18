#!/bin/bash -e
export LC_ALL="C"

if [[ "$2" == "-debug" ]] || [[ "$3" == "-debug" ]]; then
  DEBUGMODE=1
  if [[ "$2" == "-debug" ]]; then
    # dirty hack to fix assigning TARGETDIR
    # TODO: add proper params handling
    params=( "$@" );
    unset "params[1]";
    set -- "${params[@]}";
  fi
  echo "DEBUGMODE ON"
fi

if [[ -z "$1" ]]
then
    echo "Dumpfile password extractor v.1.0"
    echo "Usage: extractpaswd source_file
        extractpaswd source_file <target_directory>";
    exit 1;
fi

if [[ ! -f "$1" ]]
then
    echo "Given input is not a regular file"
    exit 1;
fi

if [[ "$2" ]] && [[ $DEBUGMODE == 0 ]] && [[ ! -d "$2" ]]
then
    echo "Given path is not a valid directory"
    exit 1;
fi

INFILE="$1"
INFILENAME=$(basename "$INFILE")
INFILEDIRNAME=$(dirname "$INFILE")
TARGETDIR=${2:-"$INFILEDIRNAME"}
TARGETDIR=${TARGETDIR%%\/}"/" #normalise TARGETDIR
OUTFILE="$TARGETDIR${INFILENAME%%.*}-out.txt"
REMAINSFILE="$TARGETDIR${INFILENAME%%.*}-out-remains.txt"
WEAKFILE="$TARGETDIR${INFILENAME%%.*}-out-weak-"
SEPARATORS=( "\|" ":" "\;" )
PATTERN="[[:print:]]+@+[[:print:]]+";
DEBUGMODE=${DEBUGMODE:-0}

if hash pv 2>/dev/null; then
   COMMAND="pv";
 else
   echo "Without 'pv' you will not be able to see the progress.
You can install it with homebrew - 'brew install pv' if you are on macOS,
or 'sudo apt-get install pv' on Debian/Ubuntu.

For now we're gonna use 'cat' instead.";
  COMMAND="cat";
fi

if [[ $DEBUGMODE == 1 ]]; then
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
  # echo "$($COMMAND -h)";
  echo "###########";
fi
exit
echo "[$(date '+%H:%M:%S')] Starting parsing file '$INFILE'"

echo "[$(date '+%H:%M:%S')] Parsing lines with '${SEPARATORS[*]}' separators"
"$COMMAND" "$INFILE" | perl -ne "print if s/(${PATTERN}[:])|(${PATTERN}[;])|(${PATTERN}[|])//g" > "$OUTFILE";

#extract remaining lines for further proccessing
echo "[$(date '+%H:%M:%S')] Extracting remaining lines for further proccessing"
"$COMMAND" "$INFILE" | perl -ne "print if not s/(${PATTERN}[:])|(${PATTERN}[;])|(${PATTERN}[|])//g" > "$REMAINSFILE"

#following secions extract flaky, weak patterns, possible crap
#
## reversed pattern "pass:email"
echo "[$(date '+%H:%M:%S')] Extracting reversed pattern 'pass:email'"
"$COMMAND" "$REMAINSFILE" | perl -ne "print if s/([:]${PATTERN})//" > "$WEAKFILE""reversed-patt.txt"
cp "$WEAKFILE""reversed-patt.txt" "$TARGETDIR""tmp.txt"

#
## email-ish pattern, allows illegal characters, missing parts
echo "[$(date '+%H:%M:%S')] Extracting weak candidates"
"$COMMAND" "$REMAINSFILE" | perl -ne 'print if s/([[:print:]]+@+([:]))//' > "$WEAKFILE""weak-cand.txt"
cat "$WEAKFILE""weak-cand.txt" >> "$TARGETDIR""tmp.txt"

echo "[$(date '+%H:%M:%S')] Preparing file with rejected candidates (for manual check)"
"$COMMAND" "$REMAINSFILE" | grep -vFf "$TARGETDIR""tmp.txt" > "$REMAINSFILE"".manual-check3"

echo "[$(date '+%H:%M:%S')] Cleaning up temporary files"
echo "[$(date '+%H:%M:%S')] ""$TARGETDIR""tmp.txt"
rm "$TARGETDIR""tmp.txt"

echo "[$(date '+%H:%M:%S')] Finished extracting"

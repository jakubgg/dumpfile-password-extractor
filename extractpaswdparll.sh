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
    echo "Dumpfile password extractor v.1.3 parallel"
    echo "Usage: ./extractpaswdparll.sh source_file
       ./extractpaswdparll.sh source_file <target_directory>
Please be aware that his version of the script requires 'parallel' package
in order to run.";
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
PATTERN="[[:print:]]+@+[[:print:]]+"
DEBUGMODE=${DEBUGMODE:-0}

if ! hash parallel 2>/dev/null; then
   echo "Without 'Parallel' package, you will not be able to run this version of
extractpassword script. Please use 'extractpaswd.sh' instead.";
  exit 1;
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
  echo "###########";
fi

echo "[$(date '+%H:%M:%S')] Starting parsing file '$INFILE'"

echo "[$(date '+%H:%M:%S')] Parsing lines with '${SEPARATORS[*]}' separators"
parallel -a "$INFILE" -k --block 100M --pipe-part --bar "perl -ne \"print if s/(${PATTERN}[:])|(${PATTERN}[;])|(${PATTERN}[|])//g\"" > "$OUTFILE";

#extract remaining lines for further proccessing
echo "[$(date '+%H:%M:%S')] Extracting remaining lines for further proccessing"
parallel -a "$INFILE" -k --block 100M --pipe-part --bar "perl -ne \"print if not s/(${PATTERN}[:])|(${PATTERN}[;])|(${PATTERN}[|])//g\"" > "$REMAINSFILE";

#following secions extract flaky, weak patterns, possible crap
#
## reversed pattern "pass:email"
echo "[$(date '+%H:%M:%S')] Extracting reversed pattern 'pass:email'"
parallel -a "$REMAINSFILE" -k --block -1 --pipe-part --bar "perl -ne \"print if s/([:]${PATTERN})//\"" >> "$WEAKFILE""reversed-patt.txt";
cp "$WEAKFILE""reversed-patt.txt" "$TARGETDIR""tmp.txt"

#
## email-ish pattern, allows illegal characters, missing parts
echo "[$(date '+%H:%M:%S')] Extracting weak candidates"
parallel -a "$REMAINSFILE" -k --block -1 --pipe-part --bar "perl -ne \"print if s/([[:print:]]+@+([:]))//\"" >> "$WEAKFILE""weak-cand.txt";
cat "$WEAKFILE""weak-cand.txt" >> "$TARGETDIR""tmp.txt"

echo "[$(date '+%H:%M:%S')] Preparing file with rejected candidates (for manual check)"
parallel -a "$REMAINSFILE" -k --block -1 --pipe-part --bar "grep -vFf \"${TARGETDIR}tmp.txt\"" >> "$REMAINSFILE.manual-check";

echo "[$(date '+%H:%M:%S')] Cleaning up temporary files"
echo "[$(date '+%H:%M:%S')] ""$TARGETDIR""tmp.txt"
rm "$TARGETDIR""tmp.txt"

echo "[$(date '+%H:%M:%S')] Finished extracting"

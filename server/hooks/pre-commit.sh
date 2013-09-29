#!/usr/bin/env bash
#
# no/short message
# big file
# temp file
# alter tag
#
# allow by string: i know what i'm doing
# trim empty lines


REPOS="$1"	# Absolute repository path
TXN="$2"	# Transaction ID of pending commit

LOGMSG=$($SVNLOOK log -t "$TXN" "$REPOS") || errexit "Log message konnte nicht ermittelt werden."
LOGMSG=$(trim "$LOGMSG")

# CHECK log message
if (( ${#LOGMSG} < $RULE_logmsg_min_length )) && ! has_force "$LOGMSG" FORCE_MSG; then
	status 10
	msg "Regel: Die log message sollte mindestens $RULE_logmsg_min_length Zeichen lang sein."
	msg "Erzwingen mit: !FORCE_MSG"
fi

# TEST for filesize of new/added files
while read -r line; do
	##msg "DEBUG: $line"
	# file has been added (new file "A   ", not copied "A + ")
	if { egrep '^A\s{3}' &>/dev/null <<<"$line"; } && ! has_force "$LOGMSG" FORCE_FILESIZE; then
		filepath=${line:4}
		filesize=$($SVNLOOK filesize -t "$TXN" "$REPOS" "$filepath") || errexit "Dateigröße konnte nicht ermittelt werden."
		
		if (( $filesize > $RULE_add_filesize_max )); then
			status 20
			msg "Regel: Dateigröße einer neuen Datei sollte kleiner/gleich $(byteshuman $RULE_add_filesize_max) sein."
			msg "Datei '$filepath' mit $(byteshuman $filesize)"
			msg "Erzwingen mit: !FORCE_FILESIZE"
		fi
	fi
done < <($SVNLOOK changed -t "$TXN" --copy-info "$REPOS")

return 0


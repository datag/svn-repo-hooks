#!/usr/bin/env bash
#
# no/short message
# big file
# temp file
# prevent alter tag

################################################################################
REPOS="$1"	# Absolute repository path
TXN="$2"	# Transaction ID of pending commit
################################################################################

RULE_logmessage_minlength=1
RULE_newfile_maxsize=$((5 * 1024*1024))

function svnlook_txn()
{
	declare cmd=$1; shift
	
	$SVNLOOK $cmd --transaction "$TXN" "$REPOS" $@
}

function reject()
{
	declare -i rc=${1:-1}
	
	(( rc > 0 )) && STATUS=rc || :
}

function has_force()
{
	declare rule=$1
	egrep -q -w '!'${rule} &>/dev/null <<<"$LOGMSG"
}

function rule_logmessage()
{
	declare cinfo=$(svnlook_txn info) || errexit "Could not get transaction info."
	declare -i cmsglen=$(sed -n -e '3{p;q}' <<<"$cinfo")
	
	if (( cmsglen < RULE_logmessage_minlength )) && ! has_force FORCE_LOGMESSAGE; then
		reject 10
		msg " RULE: The log message ($cmsglen characters) should have at least $RULE_logmessage_minlength characters."
		msg "FORCE: !FORCE_LOGMESSAGE"
		msg
	fi
}

function rule_bigfiles()
{
	declare line
	
	while read -r line; do
		##msg "DEBUG: $line"
		# file has been added (new file "A   ", not copied "A + ")
		if { egrep '^A\s{3}' &>/dev/null <<<"$line"; } && ! has_force FORCE_BIGFILES; then
			declare filepath=${line:4}
			declare -i filesize=$(svnlook_txn filesize "$filepath") || errexit "Could not get filesize of changed file."
		
			if (( filesize > RULE_newfile_maxsize )); then
				reject 20
				msg " RULE: The new file '$filepath' shouldn't be bigger than $(byteshuman $RULE_newfile_maxsize), but is $(byteshuman $filesize)."
				msg "FORCE: !FORCE_BIGFILES"
				msg
			fi
		fi
	done < <(svnlook_txn changed --copy-info)
}

################################################################################

declare -i STATUS=0
LOGMSG=$(svnlook_txn log) || errexit "Could not get transaction log message."

rule_logmessage
rule_bigfiles

return $STATUS

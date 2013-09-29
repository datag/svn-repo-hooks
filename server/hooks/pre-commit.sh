#!/usr/bin/env bash
################################################################################
REPOS="$1"	# Absolute repository path
TXN="$2"	# Transaction ID of pending commit
################################################################################

RULE_logmessage_minlength=1
RULE_newfile_maxsize=$((5 * 1024*1024))
RULE_newfile_temp=("Thumbs.db" ".DS_STORE")

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
	declare line filepath
	declare -i filesize
	
	while read -r line; do
		filepath=${line:4}
		
		# new file has been added (new file "A   ", not copied "A + ")
		if ! { { egrep -q '^A\s{3}' &>/dev/null <<<"$line"; } && [[ -f "$filepath" ]] && ! has_force FORCE_BIGFILES; } then
			continue
		fi
		
		filesize=$(svnlook_txn filesize "$filepath") || errexit "Could not get filesize of changed file."
	
		if (( filesize > RULE_newfile_maxsize )); then
			reject 20
			msg " RULE: The new file '$filepath' shouldn't be bigger than $(byteshuman $RULE_newfile_maxsize), but is $(byteshuman $filesize)."
			msg "FORCE: !FORCE_BIGFILES"
			msg
		fi
	done <<<"$CHANGED_CI"
}

function rule_tempfiles()
{
	declare line filepath filename tmp omit
	
	while read -r line; do
		filepath=${line:4}
		filename=${filepath##*/}
		
		# new file has been added (new file "A   ", not copied "A + ")
		if ! { { egrep -q '^A\s{3}' &>/dev/null <<<"$line"; } && [[ -f "$filepath" ]] && ! has_force FORCE_TEMPFILES; } then
			continue
		fi
		
		omit=
		for tmp in "${RULE_newfile_temp[@]}"; do
			if [[ "$filename" == "$tmp" ]]; then
				omit=1
				break
			fi
		done
		
		if [[ ! -z "$omit" ]]; then
			reject 20
			msg " RULE: The new file '$filepath' seems to be a temporary file and shouldn't be committed."
			msg "FORCE: !FORCE_TEMPFILES"
			msg
		fi
	done <<<"$CHANGED_CI"
}

function rule_tagsalter()
{
	: # TODO: reject modifications to /tags
}

################################################################################

declare -i STATUS=0
LOGMSG=$(svnlook_txn log) || errexit "Could not get transaction log message."
CHANGED_CI=$(svnlook_txn changed --copy-info)

rule_logmessage
rule_bigfiles
rule_tempfiles
rule_tagsalter

return $STATUS

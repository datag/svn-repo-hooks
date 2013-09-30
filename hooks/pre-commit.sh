################################################################################
REPOS="$1"
TXN="$2"
################################################################################

function svnlook_txn()
{
	declare cmd=$1; shift
	
	$SVNLOOK $cmd --transaction "$TXN" "$REPOS" "$@"
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

# svn file added:  "A   trunk/myfile"
# svn file copied: "A + trunk/myfile"	(only if ´svnlook changed´ provided with ´--copy-info´)
# ... D=deleted U=modified _U=property UU=modified&property
function is_svn_status()
{
	declare line=$1 status=$2
	declare t=$(printf "% -4s" "$status")
	egrep -q "^${t}" &>/dev/null <<<"$line"
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
		
		# is file, is new to repository ("A + " is cheap copy), and commit is not forced
		{ [[ "${filepath: -1:1}" != "/" ]] && is_svn_status "$line" "A" && ! has_force FORCE_BIGFILES; } || continue
		
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
		
		# is file, is new to repository ("A + " is cheap copy), and commit is not forced
		{ [[ "${filepath: -1:1}" != "/" ]] && is_svn_status "$line" "A" && ! has_force FORCE_TEMPFILES; } || continue
		
		filename=${filepath##*/}
		omit=
		for tmp in "${RULE_newfile_temp[@]}"; do
			if [[ "$filename" == "$tmp" ]]; then
				omit=1
				break
			fi
		done
		
		if [[ ! -z "$omit" ]]; then
			reject 30
			msg " RULE: The new file '$filepath' seems to be a temporary file and shouldn't be committed."
			msg "FORCE: !FORCE_TEMPFILES"
			msg
		fi
	done <<<"$CHANGED_CI"
}

function rule_tagsalter()
{
	declare line filepath
	
	while read -r line; do

		# existing tag has been modified
		if ! { [[ $line == tags/?* ]] && ! has_force FORCE_TAGSALTER; } then
			continue
		fi
		
		reject 40
		msg " RULE: It seems that a directory used as a tag is being modified. Tags shouldn't be modified."
		msg "FORCE: !FORCE_TAGSALTER"
		msg
	done < <(svnlook_txn dirs-changed)
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

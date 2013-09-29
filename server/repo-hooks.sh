#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset

SVNLOOK=/usr/bin/svnlook
RULE_logmsg_min_length=50
RULE_add_filesize_max=$((5 * 1024*1024))

################################################################################

declare -i STATUS=0
function status()
{
	declare -i s=${1:-1}
	(( s > 0 )) && STATUS=$s || true
}

function msg()
{
	echo ">>> $@" >&2
}

function errexit()
{
	echo "!!! Fehler: $@" >&2
	exit 1
}

# borrowed from datag/pkgbox
function trim()
{
	declare str=${1-""}
	if [[ $str =~ [[:space:]]*([^[:space:]]|[^[:space:]].*[^[:space:]])[[:space:]]* ]]; then
		echo -n "${BASH_REMATCH[1]}"
	else
		echo -n "$str"
	fi
}

# borrowed from datag/pkgbox
function byteshuman()
{
	declare -i x=${1:-0}
	awk -v x="$x" 'BEGIN { if (x<1024) { printf("%d Byte(s)", x) } else { split("KiB MiB GiB TiB PiB", t); while (x>=1024) { x/=1024; ++i }; printf("%.2f %s", x, t[i]) } }'
}

function has_force()
{
	declare log=${1-""} identifier=${2-""}
	grep "!${identifier}" &>/dev/null <<<"$log"
}

################################################################################

SCRIPT_DIR=$(dirname "$(readlink -f "$BASH_SOURCE")")
HOOK=${0##*/}
HOOK_SCRIPT="${SCRIPT_DIR}/hooks/${HOOK}.sh"

[[ -r "${HOOK_SCRIPT}" ]] || errexit "Konfigurationsfehler: Ungültiger hook '${HOOK}'."

source "${HOOK_SCRIPT}"	|| errexit "Hook '${HOOK}' gab einen Fehler zurück."
exit $STATUS


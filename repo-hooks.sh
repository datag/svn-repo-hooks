#!/usr/bin/env bash
################################################################################
# svn-repo-hooks
#
# Author: Dominik D. Geyer <dominik.geyer@gmail.com>
# Source: https://github.com/datag/svn-repo-hooks
################################################################################

set -o errexit -o pipefail -o nounset


function msg()
{
	echo ">>> $@" >&2
}

function errexit()
{
	echo "!!! Error: $@" >&2
	exit 1
}

# borrowed from datag/pkgbox
function byteshuman()
{
	declare -i x=${1:-0}
	awk -v x="$x" 'BEGIN { if (x<1024) { printf("%d Byte(s)", x) } else { split("KiB MiB GiB TiB PiB", t); while (x>=1024) { x/=1024; ++i }; printf("%.2f %s", x, t[i]) } }'
}

################################################################################

SCRIPT_DIR=$(dirname "$(readlink -f "$BASH_SOURCE")")

source "$SCRIPT_DIR/config.sh" || errexit "Main configuration cannot be loaded."

if [[ -r "$SCRIPT_DIR/config.local.sh" ]]; then
	source "$SCRIPT_DIR/config.local.sh" || errexit "Local configuration cannot be loaded."
fi

HOOK=${0##*/}
HOOK_SCRIPT="${SCRIPT_DIR}/hooks/${HOOK}.sh"

[[ -r "${HOOK_SCRIPT}" ]] || errexit "Unsupported hook '${HOOK}'."

source "${HOOK_SCRIPT}"
exit $?


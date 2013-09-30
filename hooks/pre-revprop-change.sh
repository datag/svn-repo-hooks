################################################################################
REPOS="$1"
REV="$2"
USER="$3"
PROPNAME="$4"
ACTION="$5"
################################################################################

# allow modifying log messages
if [[ "$ACTION" == "M" && "$PROPNAME" == "svn:log" ]]; then
	return 0
fi

# block everything else by default
msg "Action '$ACTION' not allowed on revision property '$PROPNAME'."
return 1

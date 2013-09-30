################################################################################
# ENVIRONMENT
################################################################################

# Set the locale
LANG=en_US.UTF-8

# Set custom environment path (use with care!)
PATH=/usr/bin:/bin
#PATH=/usr/local/bin:/usr/bin:/bin

# explicit binaries to use (if path set, provide name)
#SVNLOOK=/usr/bin/svnlook
SVNLOOK=svnlook


################################################################################
# PRE-COMMIT HOOK CONFIG
################################################################################

# minimum length for log message
RULE_logmessage_minlength=1

# maximum filesize for new files
RULE_newfile_maxsize=$((5 * 1024*1024))

# filenames which are considered "temporary" (patterns NOT yet supported)
RULE_newfile_temp=("Thumbs.db" ".DS_STORE")


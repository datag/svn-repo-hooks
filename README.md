svn-repo-hooks
==============

Random Subversion repository hooks, written in Bash.

Features
--------

Pre-commit:
  - Reject (or force-allow) empty or too short log messages.
  - Reject (or force-allow) adding new, big files.
  - Reject (or force-allow) a list of temporary files.
  - Reject (or force-allow) modifying an existing Subversion tag (path `/tags`).

Pre-revprop-change:
  - Permit modification of commit messages (revision property `svn:log`).

Setup
-----

Symlink `repo-hooks.sh` into the repository's `hook` directory for the desired hook.

Example for enabling pre-commit hooks:
```bash
$ ln -s /usr/local/svn-repo-hooks/repo-hooks.sh /var/lib/svn/MY_REPO/hooks/pre-commit
```

Example for enabling pre-revprop-change hooks:
```bash
$ ln -s /usr/local/svn-repo-hooks/repo-hooks.sh /var/lib/svn/MY_REPO/hooks/pre-revprop-change
```


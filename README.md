svn-repo-hooks
==============

Collection of Subversion repository hooks primarily aimed at providing pre-hooks – actions that are performed _before_ changes are persisted to the repository.

The hook scripts are written in Bash and make use of common tools such as sed and egrep.

Features
--------

Rules for `pre-commit`:
  - Reject (or force-allow) empty or too short log messages.
  - Reject (or force-allow) adding new, big files.
  - Reject (or force-allow) a list of temporary files.
  - Reject (or force-allow) modifying an existing Subversion tag (path `/tags`).

Rules for `pre-revprop-change`:
  - Permit modification of commit messages (revision property `svn:log`). This is more or less the original Subversion example hook.

Setup
-----

Symlink `repo-hooks.sh` into the repository's `hook` directory for the desired hook.

The following example setup is assumed for a Subversion repository `MY_REPO` located at `/var/lib/svn` and with this very scripts (`svn-repo-hooks`) copied/cloned to `/usr/local`.

Enabling pre-commit hooks:
```bash
$ ln -sf /usr/local/svn-repo-hooks/repo-hooks.sh /var/lib/svn/MY_REPO/hooks/pre-commit
```

nabling pre-revprop-change hooks:
```bash
$ ln -sf /usr/local/svn-repo-hooks/repo-hooks.sh /var/lib/svn/MY_REPO/hooks/pre-revprop-change
```

Configuration
-------------

There is a `config.sh` in the root directory. This file includes the script's environment configuration and settings for rules in hooks.

You can either edit this file directly or create a `config.local.sh` in the same directory and override variables to fit your needs.

## Description

<!-- Please include a brief description of your changes. -->

## CHECKLIST

<!--
    Filling in this checklist is mandatory! If you don't, your pull request
    will be rejected without further review. Checklists must be completed
    within 7 days of PR submission.

    Checkboxes in the REQUIRED section must be green. Even if you are only updating
    an existing script, you must follow the REQUIRED steps. Checkboxes in OPTIONAL
    should only be checked if they apply to this PR/your service.

    To check a box in markdown, make sure that it is formatted as [X] (no whitespace).
    Not formatting checkboxes correctly may break automated tools and delay PR processing.
-->

### Required

- [ ] Scripts in this pull request are written for the `bash` shell.
- [ ] This pull request was tested with the latest version of the CLI ([Latest version](https://docs.microsoft.com/cli/azure/install-azure-cli))
  - __Version tested with__ (`az --version`): 
- [ ] This pull request was tested on __at least one of__ the following platforms:
  - [ ] Linux
  - [ ] macOS
  - [ ] Windows Subsystem for Linux
- [ ] Scripts do not contain static passwords or other secret tokens.
  - [ ] New passwords are automatically generated (by the CLI, `openssl rand`, or another secure RNG method)
  - [ ] Existing secrets are user-supplied
- [ ] All prerequisite resources are listed in comments at the top of the scripts.
- [ ] All user-set variables are at the top of scripts, below imports.
- [ ] All identifiers which must be universally unique are guaranteed to be so.
- [ ] All scripts use UNIX-style line endings (LF) ([Instructions](https://help.github.com/articles/dealing-with-line-endings))

### Optional

- [ ] User-set variables have initial values guaranteed to cause the script to fail.
- [ ] Scripts in this pull request use the classic deployment model
- [ ] Scripts in this pull request use `#!/bin/bash` ('shabang') and take `ARGV` values
  - [ ] No variables must be edited in the script directly (__REQUIRED__ if above checked)
- [ ] Scripts in this pull request require extensions ([Extensions list](https://docs.microsoft.com/cli/azure/azure-cli-extensions-list)
  - [ ] Required extensions are listed at the top of the script below the shabang (if present) (__REQUIRED__ if above checked)
  - [ ] Extensions are installed by the script
  - __List of extensions and versions__:

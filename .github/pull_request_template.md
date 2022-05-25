<!--
    Thanks for contributing to the Azure CLI samples repo! For contributors, make sure that you
    fill in the PR checklist in this template, and:

    * Internal contributors: Follow the style guides and PR submission process docs:
        - CLI style guide: https://review.docs.microsoft.com/en-us/help/contribute/conventions-azure-cli?branch=master
        - Best practices: https://review.docs.microsoft.com/en-us/help/contribute/conventions-azure-scripts?branch=master
        - PR submission process: https://review.docs.microsoft.com/en-us/help/contribute/contribute-scripts-pr-process?branch=master

    * External contributors: Make sure that you test _all_ of your scripts that you modified. You can't read the contribution
        guides yet, but reviewer feedback will be detailed and clear about any required changes.
-->

## Description

<!-- Include a brief description of your changes. -->

## Checklist

<!--
    Filling in this checklist is mandatory! If you don't, your pull request
    will be rejected without further review. Checklists must be completed
    within 7 days of PR submission.

    To check a box in markdown, make sure that it is formatted as [X] (no whitespace).
    Not formatting checkboxes correctly may break automated tools and delay PR processing.
-->

- [ ] Scripts in this pull request are written for the `bash` shell.
- [ ] This pull request was tested on __at least one of__ the following platforms:
  - [ ] Linux
  - [ ] Azure Cloud Shell
  - [ ] macOS
  - [ ] Windows Subsystem for Linux
- [ ] The most recent test date and test method are recorded in the script file.
- [ ] Scripts do not contain passwords or other secret tokens that are not randomized.
- [ ] No deprecated commands or arguments are used. ([Release notes](https://docs.microsoft.com/cli/azure/release-notes-azure-cli))
- [ ] All Azure resource identifiers which must be universally unique are guaranteed to be so.
- [ ] Resource names use a random function to ensure scripts can be run multiple times in quick succession without error.
- [ ] All scripts can be run in their entirely without user input.

### Testing information

CLI version:
```
az --version
```

Extensions required:

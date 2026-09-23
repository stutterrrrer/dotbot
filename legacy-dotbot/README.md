# Legacy Dotbot setup

This directory is retained only as a rollback reference during the migration
to chezmoi. It is not used by the current setup.

## Keep for now

Keep this directory until the new Mac has been bootstrapped, the managed files
have been tested, and the application migration checklist is complete.

## Remove after migration

Once rollback is no longer needed, remove this entire directory and the root
`.gitmodules` file. The active setup is the root `Brewfile`, `.chezmoiroot`,
`home/` source directory, and the root migration documentation.

Do not run `legacy-dotbot/install` as part of the new setup. It is preserved
only for emergency rollback to the old symlink-based workflow.

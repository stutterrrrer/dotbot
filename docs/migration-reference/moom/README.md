# Moom migration reference

`Moom-settings.plist` is a reviewed export of the current Moom settings. It is
tracked in the chezmoi repository so ChatGPT or another AI tool can inspect it
and help reconstruct the settings and keymaps on a new Mac.

This is reference data, not an active chezmoi-managed target:

- It intentionally lives outside the `home/` directory selected by
  `.chezmoiroot`.
- `chezmoi apply` must never copy it to
  `~/Library/Preferences/com.manytricks.Moom.plist`.
- Do not use the reference file as a direct `defaults import` input. Recreate
  the reviewed settings and keymaps in Moom's UI, then adapt display-dependent
  layouts to the new Mac.
- If Moom changes on the source Mac, replace this export only after reviewing
  the resulting settings and confirming that it remains suitable as migration
  reference material.

The plist may contain display sizes, window frames, application names, and
other machine-specific values. Those values describe the source Mac and are
not guaranteed to be valid on another Mac.

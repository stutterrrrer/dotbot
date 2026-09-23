# Native macOS settings migration reference

These plist files are reviewed exports from the old Mac. They are tracked in
the chezmoi repository as reference material only, outside the `home/` source
directory selected by `.chezmoiroot`.

They must not be deployed wholesale with `chezmoi apply` or imported directly
into macOS preferences. The portable portions were selectively applied to the
current Mac:

- Mission Control desktop shortcuts from `symbolichotkeys.plist`
- Dock visibility, position, magnification, and Spaces ordering preference
- Dark appearance, 24-hour time, and pointer scaling from `global.plist`
- ABC/Chinese input-source selections from `hitoolbox.plist`
- Increase Contrast and Reduce Transparency from `universalaccess.plist`

The old Dock application list and `spaces.plist` display/Space identifiers were
not applied because they refer to the old Mac's applications, displays, and
Space UUIDs. Caps Lock-to-Control is not represented in this archive.

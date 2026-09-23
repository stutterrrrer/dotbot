# macOS system-settings migration inventory

This document records the user-level macOS settings observed on the source Mac
on 2026-09-23 and assigns each setting a migration owner. The audit was read
only. It does not attempt to copy preference databases into chezmoi.

The important distinction is:

- **Native macOS** owns system behavior that depends on the OS, hardware,
  displays, login session, or privacy database.
- **BetterTouchTool (BTT)** owns portable custom triggers, app-specific
  shortcuts, gestures, and window actions when those actions are deliberately
  configured in BTT and exported as a reviewed Master Preset.
- **Moom** owns the existing window-layout workflow and should be migrated by
  its preference export. Do not silently redesign Moom mappings as BTT
  mappings during this migration.
- **chezmoi** owns text configuration and reviewed portable files, not live
  macOS preference databases or permission records.

## Source-Mac findings

These values were explicitly present in the current user preference stores.
An explicit value is evidence that the setting has been recorded; it is not
always proof that the value differs from the factory default for every Mac or
macOS release.

### Keyboard, pointer, and input behavior

| Observed setting | Current value | Recommended owner | New-Mac action |
| --- | --- | --- | --- |
| Key-repeat delay | `InitialKeyRepeat=68` | Native macOS | Recreate in System Settings, then test typing feel. |
| Key-repeat rate | `KeyRepeat=5` | Native macOS | Recreate in System Settings, then test typing feel. |
| Press-and-hold behavior | `ApplePressAndHoldEnabled=0` | Native macOS | Reapply with the reviewed `defaults` command only if still wanted; log out or restart affected apps. |
| Function-key mode | `com.apple.keyboard.fnState=1` | Native macOS | Recreate under Keyboard settings; do not emulate with BTT. |
| Trackpad speed | `com.apple.trackpad.scaling=2.5` | Native macOS | Recreate for the new trackpad. |
| Mouse speed | `com.apple.mouse.scaling=4.551058` | Native macOS | Recreate for the new mouse; hardware can make the same number feel different. |
| Force Click | enabled | Native macOS | Recreate under Trackpad settings. |
| Three/four-finger gestures | several explicit gesture values in `com.apple.AppleMultitouchTrackpad` | Native macOS unless intentionally replaced | Recreate native gestures first. Use BTT only for additional custom gestures. |
| Input sources | ABC plus SCIM/ITABC and Emoji input components | Native macOS | Add the required input sources manually and test the input-source shortcut. |
| Languages | `en-US`, `zh-Hans-US` | Native macOS | Recreate under Language & Region. |
| Locale and units | `en_US`, centimetres, metric, Celsius | Native macOS | Recreate under Language & Region. |
| 24-hour clock | enabled | Native macOS | Recreate under System Settings > General > Date & Time. |

The audit found no global custom application menu shortcuts:
`NSUserKeyEquivalents` is currently empty. If an application has its own
stored keymap, migrate it with that application's supported export instead of
assuming it is represented in the global macOS shortcut store.

### Dock, hot corners, appearance, and accessibility

| Observed setting | Current value | Recommended owner | New-Mac action |
| --- | --- | --- | --- |
| Appearance | Dark mode is explicitly set | Native macOS | Recreate under Appearance. |
| Dock visibility | auto-hide enabled | Native macOS | Recreate under Desktop & Dock. |
| Dock position | right | Native macOS | Recreate under Desktop & Dock. |
| Dock size | `49` | Native macOS | Recreate under Desktop & Dock. |
| Hot corners | top-left/top-right=`2`; bottom-left/bottom-right=`4` | Native macOS or BTT, choose one owner | Verify the displayed actions in System Settings. If you want one exportable owner, reproduce the same corner triggers in BTT and disable the native duplicates. |
| Contrast/transparency | `increaseContrast=1`, `reduceTransparency=1` | Native macOS | Recreate under Accessibility > Display. Do not use BTT. |
| Clock display | 24-hour, date, and weekday visible | Native macOS | Recreate under Control Center > Clock. |
| Mission Control/Spaces layout | multiple spaces and display UUIDs recorded | Native macOS | Recreate after the new displays are connected. Do not import `com.apple.spaces` wholesale. |

Dock app membership and Spaces identifiers are machine/session state. They
should not be placed in chezmoi or treated as a portable BTT preset.

## What BTT can migrate reliably

BTT is a good portable owner for the following deliberately custom behavior:

- keyboard shortcuts that launch apps, run a reviewed shell/AppleScript
  action, or invoke a menu item;
- app-specific shortcuts and triggers;
- custom trackpad, mouse, or keyboard gestures that are not replacing a
  required native gesture;
- window move/resize actions and custom window layouts;
- hot-corner actions, if BTT is chosen as the single owner and the corresponding
  native hot corners are disabled;
- text expansion and other BTT-native triggers, subject to reviewing any
  embedded scripts or sensitive text.

Export the BTT Master Preset as JSON, inspect it, transfer it privately, and
import it on the new Mac. Grant BTT Accessibility permission before testing.
Keep the JSON export outside the repository if it contains scripts, paths,
tokens, or personal data. BTT's optional iCloud preset sync can help with
future Macs, but retain a reviewed JSON export because the vendor describes
that sync as experimental.

Do not configure the same shortcut in both native macOS and BTT unless the
duplication is intentional. One owner avoids double actions and makes future
troubleshooting much easier.

## What BTT should not own

Use native macOS or the relevant dedicated tool for these items:

- modifier-key remapping and low-level device rules: System Settings or a
  dedicated remapper only if you intentionally choose one;
- input-source installation and language switching: System Settings;
- key-repeat, function-key mode, scrolling direction, pointer speed, Force
  Click, and accessibility display options: System Settings;
- Mission Control/Spaces topology, display arrangement, scaling, and
  display-specific behavior: System Settings after the hardware is connected;
- Accessibility, Input Monitoring, Screen Recording, Full Disk Access, and
  other TCC privacy approvals: manually reapprove on the new Mac;
- FileVault, login items, security tokens, VPN/network profiles, and account
  or license state: dedicated migration or account workflow.

Native Keyboard Shortcuts are preferable for built-in Mission Control,
Spotlight, screenshot, Services, input-source, and modifier shortcuts when
they already express the desired behavior. BTT can imitate many of them, but
that imitation adds an Accessibility dependency and can break when Apple
changes a menu or system action.

The source Mac currently has these symbolic-hotkey records enabled:
`7, 9, 33, 35, 53, 54, 55, 56, 61, 64, 79, 80, 81, 82, 98, 118, 119,
120, 121, 122, 123, 124, 163, 164, 176, 190`. These numbers are useful for
comparing machines, but macOS does not expose them as stable human-readable
names in the preference store. Identify each user-facing action in System
Settings before deciding whether it belongs in native macOS or BTT; do not
import the numeric records wholesale.

## Private diagnostic backup, if needed

For rollback evidence only, export the relevant domains to a private Desktop
folder. Do not commit them or import them blindly on the new OS:

```sh
defaults export com.apple.symbolichotkeys "$HOME/Desktop/com.apple.symbolichotkeys.plist"
defaults export com.apple.dock "$HOME/Desktop/com.apple.dock.plist"
defaults export com.apple.HIToolbox "$HOME/Desktop/com.apple.HIToolbox.plist"
```

The `com.apple.symbolichotkeys` and `com.apple.dock` stores contain numeric
implementation details and session/display state. Recreate the user-facing
choices in System Settings unless a specific, reviewed setting is known to be
safe to restore.

## Repeat the audit

Run the repository's read-only audit script on either Mac:

```sh
/Users/ian/.dotfiles/scripts/audit-macos-migration-settings.sh \
  > "$HOME/Desktop/macos-settings-audit.txt"
```

The output is intended for private review. It intentionally reports selected
settings and paths rather than copying any preference database into chezmoi.

## Official references

- [Apple: Change Keyboard Shortcuts settings on Mac](https://support.apple.com/en-euro/guide/mac-help/mchlp2864/mac)
- [Apple: Create keyboard shortcuts for apps on Mac](https://support.apple.com/en-is/guide/mac-help/mchlp2271/mac)
- [Apple: Change Modifier Keys settings on Mac](https://support.apple.com/en-tj/guide/mac-help/mchlp1011/mac)
- [BetterTouchTool presets](https://docs.folivora.ai/docs/configuration/presets/)
- [BetterTouchTool restoring backups](https://docs.folivora.ai/docs/configuration/restoring-backups/)

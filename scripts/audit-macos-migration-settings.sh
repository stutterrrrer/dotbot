#!/bin/zsh

# Print a read-only, intentionally limited inventory of user-facing macOS
# settings that commonly matter during a Mac migration. This script does not
# modify preferences and does not copy preference databases into chezmoi.

set -u

print_section_header() {
    local section_title="$1"
    printf '\n--- %s ---\n' "$section_title"
}

print_global_preference() {
    local preference_key="$1"
    local preference_value

    preference_value="$(defaults read -g "$preference_key" 2>/dev/null || true)"
    if [[ -n "$preference_value" ]]; then
        printf '%s=%s\n' "$preference_key" "$preference_value"
    else
        printf '%s=<not explicitly stored>\n' "$preference_key"
    fi
}

print_domain_preference() {
    local preference_domain="$1"
    local preference_key="$2"
    local preference_value

    preference_value="$(defaults read "$preference_domain" "$preference_key" 2>/dev/null || true)"
    if [[ -n "$preference_value" ]]; then
        printf '%s %s=%s\n' "$preference_domain" "$preference_key" "$preference_value"
    else
        printf '%s %s=<not explicitly stored>\n' "$preference_domain" "$preference_key"
    fi
}

print_section_header "system"
sw_vers

print_section_header "global keyboard, pointer, appearance, and locale preferences"
for global_preference_key in \
    AppleInterfaceStyle \
    AppleLanguages \
    AppleLocale \
    AppleMeasurementUnits \
    AppleMetricUnits \
    AppleTemperatureUnit \
    AppleICUForce24HourTime \
    AppleShowScrollBars \
    AppleMiniaturizeOnDoubleClick \
    ApplePressAndHoldEnabled \
    AppleKeyboardUIMode \
    InitialKeyRepeat \
    KeyRepeat \
    com.apple.keyboard.fnState \
    com.apple.mouse.scaling \
    com.apple.mouse.doubleClickThreshold \
    com.apple.trackpad.scaling \
    com.apple.trackpad.forceClick \
    com.apple.trackpad.scrolling; do
    print_global_preference "$global_preference_key"
done

print_section_header "Dock and hot corners"
for dock_preference_key in \
    autohide \
    orientation \
    tilesize \
    magnification \
    largesize \
    wvous-tl-corner \
    wvous-tr-corner \
    wvous-bl-corner \
    wvous-br-corner \
    wvous-tl-modifier \
    wvous-tr-modifier \
    wvous-bl-modifier \
    wvous-br-modifier; do
    print_domain_preference com.apple.dock "$dock_preference_key"
done

print_section_header "input sources"
print_domain_preference com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID
print_domain_preference com.apple.HIToolbox AppleEnabledInputSources
print_domain_preference com.apple.HIToolbox AppleSelectedInputSources

print_section_header "accessibility display and keyboard settings"
for accessibility_preference_key in \
    increaseContrast \
    reduceTransparency \
    slowKey \
    stickyKey \
    closeViewZoomFactor \
    keyboardAccessFocusRingTimeout; do
    print_domain_preference com.apple.universalaccess "$accessibility_preference_key"
done

print_section_header "clock menu"
for clock_preference_key in Show24Hour ShowDate ShowDayOfWeek IsAnalog; do
    print_domain_preference com.apple.menuextra.clock "$clock_preference_key"
done

print_section_header "global application shortcuts"
global_application_shortcuts="$(defaults read -g NSUserKeyEquivalents 2>/dev/null || true)"
if [[ -n "$global_application_shortcuts" ]]; then
    printf '%s\n' "$global_application_shortcuts"
else
    printf '%s\n' '<none explicitly stored>'
fi

print_section_header "enabled symbolic hotkey IDs"
# These numeric IDs are useful for comparing two Macs, but they are an
# implementation detail. Use System Settings to identify the corresponding
# user-facing action before recreating it in BTT.
defaults export com.apple.symbolichotkeys - 2>/dev/null \
    | plutil -convert json -o - - 2>/dev/null \
    | jq -r '.AppleSymbolicHotKeys | to_entries[] | select(.value.enabled == true) | [.key, .value.value.type, (.value.value.parameters | tostring)] | @tsv' \
    | sort -n

print_section_header "migration-relevant application state paths"
for migration_path in \
    "$HOME/Library/Application Support/BetterTouchTool" \
    "$HOME/Library/Preferences/com.hegenberg.BetterTouchTool.plist" \
    "$HOME/Library/Preferences/com.manytricks.Moom.plist" \
    "$HOME/.config/karabiner"; do
    if [[ -e "$migration_path" ]]; then
        printf 'present: %s\n' "$migration_path"
    else
        printf 'missing: %s\n' "$migration_path"
    fi
done

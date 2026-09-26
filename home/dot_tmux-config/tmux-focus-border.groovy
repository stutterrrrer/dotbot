// IntelliJ startup script: tells tmux whether an IntelliJ terminal has
// keyboard focus, so tmux can gray out its active pane border while you're in
// the editor (see "active but the terminal itself is unfocused" in
// ~/.tmux.conf).
//
// Why a script: IntelliJ's terminal emulator (JediTerm) has no focus-reporting
// mode (xterm DECSET 1004), so unlike iTerm it never sends tmux CSI I / CSI O
// when focus moves between the Terminal tool window and the editor. tmux's
// client-focus-in/out hooks therefore never fire for the IntelliJ client.
//
// How it runs: IntelliJ's IdeStartupScripts runs every file in
// <config dir>/extensions/com.intellij/startup/ once per IDE launch, when the
// first project opens, using the script engine for the file extension
// (Groovy is bundled). To apply edits without restarting, paste this file
// into Tools > IDE Scripting Console (Groovy) and run it: it replaces the
// previously registered listener instead of adding a second one.
//
// Managed by chezmoi: edit ~/.chezmoi/home/dot_tmux-config/tmux-focus-border.groovy,
// then `chezmoi apply`. IntelliJ's config dir is version-specific
// (IntelliJIdea2026.2, ...), so chezmoi deploys this file to
// ~/.tmux-config/ and run_after_install-intellij-startup-scripts.sh copies it
// into every IntelliJ config dir on each apply, including new versions.
//
// If the border stops graying in IntelliJ (new Mac, IntelliJ upgrade), check
// in this order (iTerm graying still works = the tmux side is fine):
// 1. Is the copy there? ls ~/Library/Application\ Support/JetBrains/*/extensions/com.intellij/startup/
//    The copy step only sees config dirs that already exist, so on a new Mac
//    or after a major upgrade, launch IntelliJ once, then `chezmoi apply`
//    again and restart IntelliJ.
// 2. Did it load? grep tmux-focus-border ~/Library/Logs/JetBrains/*/idea.log
//    Expect "tracking terminal focus for tmux via ...". A Groovy error or
//    "not supported (no script engine)" means the Groovy plugin is disabled,
//    or the startup-scripts folder moved (IdeStartupScripts class in
//    lib/intellij.platform.lang.impl.jar).
// 3. Does it see the terminal? Watch `tmux show -gv @intellij-focused` while
//    clicking editor <-> terminal: it should flip 0/1. If it stays 1 or 0,
//    JetBrains probably renamed the terminal packages; update
//    terminalPackagePrefixes below (print the focus owner's parent classes
//    from the IDE Scripting Console to find the new names).
// 4. Does tmux still treat IntelliJ as "no focus reporting"? tmux list-clients
//    -F '#{client_tty} [#{client_termtype}]' - the IntelliJ client must show
//    []. If IntelliJ ever starts answering XTVERSION (or supports DECSET 1004
//    natively), revisit the rule in ~/.tmux.conf.

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.diagnostic.Logger

import java.awt.Component
import java.awt.KeyboardFocusManager
import java.awt.event.ActionListener
import java.beans.PropertyChangeListener
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import javax.swing.Timer

final Logger log = Logger.getInstance('tmux-focus-border')

// the IDE is launched from the Dock, so its PATH doesn't include Homebrew
final String tmuxExecutable = ['/opt/homebrew/bin/tmux', '/usr/local/bin/tmux'].find { new File(it).canExecute() }
if (tmuxExecutable == null) {
    log.warn('tmux not found, not tracking terminal focus')
    return
}

// Terminal views (reworked and classic) live in these packages, whether the
// terminal is in the tool window or moved to an editor tab. The focus owner
// itself is often a generic component (e.g. the editor component the
// reworked terminal renders into), so walk up its parents.
final List<String> terminalPackagePrefixes = [
    'com.intellij.terminal.',
    'org.jetbrains.plugins.terminal.',
    'com.jediterm.',
]
def isInsideTerminal = { Component component ->
    for (Component current = component; current != null; current = current.parent) {
        String className = current.class.name
        if (terminalPackagePrefixes.any { className.startsWith(it) }) return true
    }
    return false
}

// One thread, so tmux calls run in the order focus changed (a fast
// editor -> terminal click can't have its "1" overtaken by the earlier "0").
// Replaces the executor from a previous run of this script.
final String executorKey = 'ian.tmuxFocusBorder.executor'
def previousExecutor = System.properties.get(executorKey)
if (previousExecutor instanceof ExecutorService) previousExecutor.shutdown()
final ExecutorService tmuxExecutor = Executors.newSingleThreadExecutor()
System.properties.put(executorKey, tmuxExecutor)

def sendFocusToTmux = { boolean terminalFocused ->
    tmuxExecutor.execute({
        try {
            // -N: don't start a tmux server if none is running.
            // The ';' argument separates tmux commands (the shell's `\;`).
            // Re-running client-focus-in recomputes the border from all
            // clients, so this works the same whichever hook it runs.
            // One call takes ~5ms, so this adds no visible lag.
            new ProcessBuilder(tmuxExecutable, '-N',
                    'set-option', '-g', '@intellij-focused', terminalFocused ? '1' : '0', ';',
                    'set-hook', '-R', 'client-focus-in')
                .redirectErrorStream(true)
                .redirectOutput(ProcessBuilder.Redirect.DISCARD)
                .start()
                .waitFor()
        } catch (Exception exception) {
            log.warn('failed to update tmux focus state', exception)
        }
    } as Runnable)
}

// Only call tmux when the terminal/non-terminal state actually changes.
Boolean lastSentTerminalFocused = null
def updateFromCurrentFocus = {
    boolean terminalFocused = isInsideTerminal(KeyboardFocusManager.currentKeyboardFocusManager.focusOwner)
    if (terminalFocused != lastSentTerminalFocused) {
        lastSentTerminalFocused = terminalFocused
        sendFocusToTmux(terminalFocused)
    }
}

// Focus landing on a real component is acted on immediately (a brief detour
// through a non-terminal component just costs an extra ~5ms tmux call).
// Focus going to null is often a transient mid-transfer state, so only that
// case waits briefly; if focus is still null afterwards, the IDE really lost
// app focus (e.g. switched to iTerm), which counts as not focused, same as a
// real terminal.
final Timer nullFocusTimer = new Timer(100, { updateFromCurrentFocus() } as ActionListener)
nullFocusTimer.repeats = false

final KeyboardFocusManager focusManager = KeyboardFocusManager.currentKeyboardFocusManager
final String listenerKey = 'ian.tmuxFocusBorder.listener'
def previousListener = System.properties.get(listenerKey)
if (previousListener instanceof PropertyChangeListener) {
    focusManager.removePropertyChangeListener('focusOwner', previousListener)
}
PropertyChangeListener focusOwnerListener = { event ->
    if (event.newValue == null) {
        nullFocusTimer.restart()
    } else {
        nullFocusTimer.stop()
        updateFromCurrentFocus()
    }
} as PropertyChangeListener
focusManager.addPropertyChangeListener('focusOwner', focusOwnerListener)
System.properties.put(listenerKey, focusOwnerListener)

updateFromCurrentFocus() // send the current state right away
log.info("tracking terminal focus for tmux via $tmuxExecutable")

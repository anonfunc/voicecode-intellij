# IntelliJ support for VoiceCode

This adds [VoiceCode](https://voicecode.io) support for IntelliJ.

This mode also supports:

- Android Studio
- AppCode
- CLion
- DataGrip
- GoLand
- MPS
- PhpStorm
- PyCharm (Professional and Community editions)
- RubyMine
- WebStorm

However, my primary use case is currently Java and IntelliJ CE.  I will not be able to debug or reproduce issues occuring outside of the freely available IDEs.  (Pull requests are welcome. :smile:)  Support for these IDEs is contingent on their menu items remaining very similar, see *Limitations*.

## Installation

### Make required IntelliJ config changes:

- [Disable cut/copy acting without an active selection.](https://stackoverflow.com/questions/32895522/disable-copying-entire-line-when-nothing-is-selected-in-intellij)
- Change keymap to "Mac OS X 10.5+". (Or update package settings to match current keymap.  See below.)

### Clone this repo into the Voicecode home directory

By default, this is `~/voicecode`, so:

    git clone https://github.com/anonfunc/voicecode-intellij.git ~/voicecode/intellij
    
### You should not need to restart VoiceCode, but if it doesn't work... restart VoiceCode.

### Enable the package commands in VoiceCode.

### [Import and train vocabulary in Dragon](http://voicecode.io/doc/vocabulary).

## Limitations

- Uses accessibility API to trigger actions by their menu items.  Menu item names should hopefully be identical across supported IDEs and slow to change across IDE releases.
- Assumes keymap does not modify basic OS X movement: Command-Left/Right, Shift-Up/Down, etc.
- Needs configuration if not using the "OS X 10.5" keymap in order for `folly` to work.
- The template command `quinn` has a specific set of template names, none of which match with IntelliJ's included templates, making it less useful until configured.

# Configuring for a different keymap

This section only affects the following commands:

- folly (selection:block)
- idea fix this (intellij:quick-fix)

If not using the "OS X 10.5" keymap, set (all or some of) the following in your VoiceCode settings:

    # Editor Actions | Move Caret to Code Block Start
    Settings.intellij.previousBlock = ['[', 'command']
    # Editor Actions | Move Caret to Code Block End with Selection
    Settings.intellij.selectToNextBlock = [']', 'command shift']

    # Other | Show Intention Actions
    # Note that this is the same for all OS X keymaps, and you probably don't need to set it.
    Settings.intellij.showIntentionActions = ['enter', 'option']

This example is for the "OS X" keymap, so you might be able to just copy and paste the first two settings as-is. (We're not using the block object assignment, since VoiceCode treats that as a deep merge, which will append the array contents and make a mess of things.)

# Credits

- anonfunc
- TerjeB

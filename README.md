# IntelliJ support for VoiceCode

This adds [VoiceCode](https://voicecode.io) support for IntelliJ, implementing all `editor` commands which make sense.

## Installation

### Make required IntelliJ config changes:

- [Disable cut/copy acting without an active selection.](https://stackoverflow.com/questions/32895522/disable-copying-entire-line-when-nothing-is-selected-in-intellij)
- Change keymap to `Mac OS X 10.5+`.

### Clone this repo into the Voicecode home directory

By default, this is `~/voicecode`, so:

    git clone https://github.com/anonfunc/voicecode-intellij.git ~/voicecode/intellij
    
### You should not need to restart VoiceCode, but if it doesn't work... restart VoiceCode.

## Limitations

- Uses nothing but keyboard shortcuts, so is keyboard mapping dependent.  
- The scope does not include any IDEA family IDE besides IntelliJ community edition.  Please open a pull request with the appropriate bundle ID (and full application names) if you have it.
- The template command `quinn` has a specific set of template names, none of which match with IntelliJ's included templates.
- Stomps on bookmark 0, if set.  Bookmark 0 is used to store original cursor location for commands like `clonesert`.  (Should replace with getting current position via Cmd-L and then modifying the line number based on operation.)

# Credits

- anonfunc
- TerjeB

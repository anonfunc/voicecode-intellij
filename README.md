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

However, my primary use case is currently Java and IntelliJ CE.  I will not be able to debug or reproduce issues occuring outside of the freely available IDEs.  (Pull requests are welcome. :smile:)

## Installation

### Clone this repo into the Voicecode home directory

By default, this is `~/voicecode`, so:

    git clone https://github.com/anonfunc/voicecode-intellij.git ~/voicecode/intellij
    
### You should not need to restart VoiceCode, but if it doesn't work... restart VoiceCode.

### Enable the package commands in VoiceCode.

### Make required IntelliJ config changes:

- [Disable cut/copy acting without an active selection.](https://stackoverflow.com/questions/32895522/disable-copying-entire-line-when-nothing-is-selected-in-intellij)
- Install the IDE Plugin.

### [Import and train vocabulary in Dragon](http://voicecode.io/doc/vocabulary).

## Limitations

- The template command `quinn` has a specific set of template names, none of which match with IntelliJ's included templates, making it less useful until configured.

# Credits

- anonfunc
- TerjeB
- biegel
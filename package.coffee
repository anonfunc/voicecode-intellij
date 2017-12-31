# https://stackoverflow.com/questions/32895522/disable-copying-entire-line-when-nothing-is-selected-in-intellij

pack = Packages.register
  name: 'intellij'
  description: 'Jetbrains IntelliJ IDEA integration'

Scope.register
  name: "intellij"
  applications: [
    'com.jetbrains.intellij.ce'
  ]

# TODO: Determine when I can use @key vs. key code scripting.
# All of this assumes using OS X 10.5+ keymap!
pack.implement
  scope: 'intellij',
  'editor:move-to-line-number': (input) ->
    # Cmd-L
    @applescript 'tell application "System Events" to key code 37 using command down'
    @delay 50
    @string parseInt(input)
    @delay 50
    @key 'Enter'
    @delay 50
  'object:duplicate': ->
    # Cmd-D
    @applescript 'tell application "System Events" to key code 2 using command down'
  'editor:toggle-comments': ->
    # Cmd-/
    @applescript 'tell application "System Events" to key code 44 using command down'
  'editor:expand-selection-to-scope': ->
    @applescript 'tell application "System Events" to key code 126 using option down'
  'editor:insert-from-line-number': (input) ->
    # store clipboard
    clipboard = @getClipboard()
    # Store current position: Opt-F3, 0
    @applescript 'tell application "System Events" to key code 99 using option down'
    @delay 50
    @applescript 'tell application "System Events" to key code 29'
    @delay 50
    # Jump to line (see above)
    @do 'editor:move-to-line-number', input
    @delay 50
    # Select line and copy: Command left, Shift command right, Cmd-C
    @applescript 'tell application "System Events" to key code 123 using command down'
    @delay 50
    @applescript 'tell application "System Events" to key code 124 using {command down, shift down}'
    @delay 50
    @applescript 'tell application "System Events" to key code 8 using command down'
    @delay 50
    # Jump to original position: Ctrl-0
    @applescript 'tell application "System Events" to key code 29 using control down'
    @delay 50
    # Clear bookmark
    @applescript 'tell application "System Events" to key code 99'
    # Paste: Cmd-V
    @applescript 'tell application "System Events" to key code 9 using command down'
    @delay 50
    # Restore clipboard
    @setClipboard(clipboard)
  'editor:open-command-pallet': ->
    @key 'a', 'command shift'
  'editor:expand-selection-to-indentation': ->
    @key '[', 'command option'
    @delay 50
    @key ']', 'command option shift'
  'editor:insert-code-template': (args)->
    # XXX The intellij ones don't match up with expected template names.
    # Create templates matching VC?   Or make VC templates match intellij?
    # (or freeform...)
    #@key 'j', 'command'
    @applescript 'tell application "System Events" to key code 38 using command down'
    console.log args.codesnippet
    if args.codesnippet
      @delay 100
      @string args.codesnippet
      @delay 50
      @key 'enter'
  'editor:select-line-number-range': (input) ->
    if input
      number = input.trim()
      length = Math.floor(number.length / 2)
      first = number.substr(0, length)
      last = number.substr(length, length + 1)
      first = parseInt(first)
      last = parseInt(last)
      if last < first 
        temp = last
        last = first
        first = temp
      # Jump to line (see above)
      @do 'editor:move-to-line-number', first
      @delay 50
      @key 'left', 'command'
      @delay 25
      while first < last
        console.log first
        @key 'down', 'shift'
        first++
        @delay 25
      @key 'right', 'command shift'
  'editor:extend-selection-to-line-number': (input) ->
    if input
      clipboard = @getClipboard()
      @key 'l', 'command'
      @delay 100
      @do 'clipboard:copy'
      @delay 25
      @key 'escape'
      copied = _.split @getClipboard(), ':'
      currentLineNumber = parseInt(copied[0])
      target = parseInt(input)
      if currentLineNumber < target
        counter = currentLineNumber
        while counter < target
          @key 'down', 'shift'
          @delay 25
          counter++
        @key 'right', 'command shift'
      else
        counter = target
        while counter < currentLineNumber
          @key 'up', 'shift'
          @delay 25
          counter++
        @key 'left', 'command shift'
      @setClipboard(clipboard)
  'editor:select-line-number': (input) ->
    @do 'editor:move-to-line-number', input
    @delay 50
    @key 'left', 'command'
    @delay 25
    @key 'right', 'command shift'
  'editor:move-to-line-number-and-way-left': (input) ->
    @do 'editor:move-to-line-number', input
    @delay 50
    @key 'left', 'command'
  'editor:move-to-line-number-and-way-right': (input) ->
    @do 'editor:move-to-line-number', input
    @delay 50
    @key 'right', 'command'
  'editor:insert-under-line-number': (input) ->
    @do 'editor:move-to-line-number', input
    @delay 50
    @key 'right', 'command'
    @delay 25
    @key 'enter'
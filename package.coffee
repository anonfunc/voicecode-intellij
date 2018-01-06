# https://stackoverflow.com/questions/32895522/disable-copying-entire-line-when-nothing-is-selected-in-intellij

pack = Packages.register
  name: 'intellij'
  description: 'Jetbrains IntelliJ IDEA (and friends) integration'

Scope.register
  name: "intellij"
  applications: [
    'com.jetbrains.intellij',  # Also used by MPS
    'com.jetbrains.intellij.ce',
    'com.jetbrains.AppCode',
    'com.jetbrains.CLion',
    'com.jetbrains.datagrip',
    'com.jetbrains.goland',
    'com.jetbrains.PhpStorm',
    'com.jetbrains.pycharm',
    'com.jetbrains.rubymine',
    'com.jetbrains.WebStorm',
    'com.google.android.studio'
  ]

_.extend Settings,
  darwin:
    applicationsThatNeedExplicitModifierPresses: [
      'IntelliJ IDEA',
      'IntelliJ IDEA CE',
      'AppCode',
      'CLion',
      'DataGrip',
      'GoLand',
      'MPS'
      'PhpStorm',
      'PyCharm',
      'PyCharm CE',
      'RubyMine',
      'WebStorm',
      'Android Studio'
    ]

# TODO: Determine when I can use @key vs. key code scripting.
# All of this assumes using OS X 10.5+ keymap!
pack.implement
  scope: 'intellij',
  # Object package
  'object:duplicate': ->
    # Cmd-D
    @key 'd', 'command'
  'object:backward': ->
    # Previous edit location
    @key '[', 'command'
  'object:forward': ->
    # Next edit location
    @key ']', 'command'
  'object:refresh': ->
    # Synchronize.
    @key 'y', 'command option'
  'object:next': ->
    # Next method?
    @key 'down', 'control'
  'object:previous': ->
    # Previous method?
    @key 'up', 'control'
  # Editor package
  'editor:move-to-line-number': (input) ->
    # Cmd-L
    @key 'l', 'command'
    @delay 50
    @string parseInt(input)
    @delay 50
    # @key 'Enter'
    @enter()
    @delay 50
  'editor:toggle-comments': ->
    @key '/', 'command'
  'editor:expand-selection-to-scope': ->
    @key 'up', 'option'
  'editor:insert-from-line-number': (input) ->
    # store old clipboard
    clipboard = @getClipboard()
    # Store current position at bookmark 0
    @key '0', 'control shift'
    @delay 50
    # Jump to line (see above)
    @do 'editor:move-to-line-number', input
    @delay 50
    # Select line and copy: Command left, Shift command right, Cmd-C
    @key 'left', 'command'
    @delay 50
    @key 'right', 'command shift'
    @delay 50
    @key 'c', 'command'
    @delay 50
    # Jump to bookmark 0, our original position:
    @key '0', 'control'
    @delay 50
    # Clear bookmark
    @key '0', 'control shift'
    # Paste.
    @key 'v', 'command'
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
    @key 'j', 'command'
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
  'editor:list-projects': ->
    # Recent files, not projects.
    @key 'e', 'command'
  'delete:lines': (input) ->
    if input
      # Store current position: Ctrl-Shift-0
      @key '0', 'control shift'
      @delay 50
      first = input.first
      if 'last' in input
        # No idea how this is triggered.
        @do 'editor:select-line-number-range', '' + first + last
      else
        @do 'editor:move-to-line-number', first
      @delay 100
      @key 'delete', 'command'
      @delay 25
      # Jump to original position: Ctrl-0
      @key '0', 'control'
      @delay 50
      # Clear bookmark
      @key '0', 'control shift'
    else
      @key 'delete', 'command'

pack.command 'intellij-complete',
  spoken: 'comply'
  description: 'Trigger completion.'
  action: ->
    @key 'space', 'control'

pack.command 'intellij-smart-complete',
  spoken: 'schmaltz'
  description: 'Trigger smart completion.  Do it again to search deeper.'
  action: ->
    @key 'space', 'control shift'

pack.command 'intellij-smart-finish',
  spoken: 'finagle'
  description: 'Smart finish.  Balances parens, braces, etc.'
  action: ->
    @key 'enter', 'control shift'

pack.command 'intellij-zoom-editor',
  spoken: 'idea zoom'
  description: 'Toggle maximizing editor'
  action: ->
    @key 'F12', 'command shift'

pack.command 'intellij-find-usage',
  spoken: 'idea find usage'
  description: 'Toggle maximizing editor'
  action: ->
    @key 'F7', 'option'

pack.command 'intellij-refactor',
  spoken: 'idea reflector'
  description: 'Open refactor dialog'
  action: ->
    @key 't', 'control'

pack.command 'intellij-quick-fix',
  spoken: 'idea fix this'
  description: 'Open quick fix dialog'
  action: ->
    @key 'enter', 'option'

pack.command 'intellij-quick-fix-next',
  spoken: 'idea fix next'
  description: 'Open quick fix dialog'
  action: ->
    @key 'f2'
    @delay 50
    @key 'enter', 'option'

pack.command 'intellij-quick-fix-previous',
  spoken: 'idea fix previous'
  description: 'Open quick fix dialog'
  action: ->
    @key 'f2', 'shift'
    @delay 50
    @key 'enter', 'option'
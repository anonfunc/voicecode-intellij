# https://stackoverflow.com/questions/32895522/disable-copying-entire-line-when-nothing-is-selected-in-intellij

pack = Packages.register
  name: 'intellij'
  description: 'Jetbrains IntelliJ IDEA (and friends) integration'

pack.settings
  # Editor Actions | Move Caret to Code Block Start
  previousBlock: ['[', 'command option']
  # Editor Actions | Move Caret to Code Block End with Selection
  selectToNextBlock: [']', 'command option shift']
  # Other | Show Intention Actions
  showIntentionActions: ['enter', 'option']

_a = global.Actions

position = () ->
  _a.openMenuBarPath(['Navigate', 'Line/Column...'])
  _a.delay 100
  copied = _.split _a.getSelectedText(), ':'
  _a.delay 25
  _a.key 'escape'
  copied

Scope.register
  name: 'intellij'
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

pack.implement
  scope: 'intellij',
  # Object package
  'object:duplicate': ->
    @openMenuBarPath(['Edit', 'Duplicate Line'])
  'object:backward': ->
    @openMenuBarPath(['Navigate', 'Back'])
  'object:forward': ->
    @openMenuBarPath(['Navigate', 'Forward'])
  'object:refresh': ->
    # Synchronize.
    @openMenuBarPath(['File', 'Synchronize'])
  'object:next': ->
    # Next method?
    @openMenuBarPath(['Navigate', 'Next Method'])
  'object:previous': ->
    # Previous method?
    @openMenuBarPath(['Navigate', 'Previous Method'])
  # Editor package
  'editor:move-to-line-number': (input) ->
    # Cmd-L
    @openMenuBarPath(['Navigate', 'Line/Column...'])
    @delay 50
    @string parseInt(input)
    @delay 50
    @enter()
    @delay 50
  'editor:toggle-comments': ->
    @openMenuBarPath(['Code', 'Comment with Line Comment'])
  'editor:expand-selection-to-scope': ->
    @openMenuBarPath(['Edit', 'Extend Selection'])
  'editor:insert-from-line-number': (input) ->
    # store old clipboard
    clipboard = @getClipboard()
    currentPosition = position()
    # Jump to line (see above)
    @do 'editor:move-to-line-number', input
    @delay 50
    # Select line and copy: Command left, Shift command right, Cmd-C
    # Would a keymap ever be able to mess with this?
    # Yes, but the two OS X keymaps do not.
    @key 'left', 'command'
    @delay 50
    @key 'right', 'command shift'
    @delay 50
    @copy()
    @delay 50
    # Jump to our exact original position:
    @openMenuBarPath(['Navigate', 'Line/Column...'])
    @delay 50
    @string currentPosition[0] + ':' + currentPosition[1]
    @delay 50
    @enter()
    # Paste.
    @paste()
    @delay 50
    # Restore clipboard
    @setClipboard(clipboard)
  'editor:open-command-pallet': ->
    @openMenuBarPath(['Help', 'Find Action...'])
  'selection:block': ->  # Close to 'editor:expand-selection-to-indentation', but I dunno how that one is going to work.
    # No menu items for cursor movement!
    @key pack.settings().previousBlock[0], pack.settings().previousBlock[1]
    @delay 50
    @key pack.settings().selectToNextBlock[0], pack.settings().selectToNextBlock[1]
  'editor:insert-code-template': (args)->
    # XXX The intellij ones don't match up with expected template names.
    # Create templates matching VC?   Or make VC templates match intellij?
    # (or freeform...)
    @openMenuBarPath(['Code', 'Insert Live Template...'])
    @delay 50
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
        @key 'down', 'shift'
        first++
        @delay 25
      @key 'right', 'command shift'
  'editor:extend-selection-to-line-number': (input) ->
    if input
      @openMenuBarPath(['Navigate', 'Line/Column...'])
      @delay 100
      copied = _.split @getSelectedText(), ':'
      @delay 25
      @key 'escape'
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
    @openMenuBarPath(['View', 'Recent Files'])
  'delete:lines': (input) ->
    if input
      # Store current position:
      currentPosition = position()
      first = input.first
      if parseInt(first) <= parseInt(currentPosition[0])
        # Deleting a single line above my line, so we'll have to jump back to a higher line to compensate.
        currentPosition[0] = '' + (parseInt(currentPosition[0]) - 1)
      if 'last' in input
        # No idea how this path would be triggered.
        @do 'editor:select-line-number-range', '' + first + last
      else
        @do 'editor:move-to-line-number', first
      @delay 100
      # 'Delete line' has no menu bar item!
      # Script the longer way: command right, shift command left, delete x2
      @key 'right', 'command'
      @delay 25
      @key 'left', 'command shift'
      @delay 25
      @key 'delete'
      @delay 25
      @key 'delete'
      @delay 25
      # Jump to our exact original position:
      @openMenuBarPath(['Navigate', 'Line/Column...'])
      @delay 50
      @string currentPosition[0] + ':' + currentPosition[1]
      @delay 50
      @enter()
    else
      # Delete line has no menu bar item!
      # @key 'delete', 'command'
      # Script the longer way: command right, shift command left, delete
      # This has a small advantage in that it matches snipline behavior in other editors by leaving an empty line.
      @key 'right', 'command'
      @delay 25
      @key 'left', 'command shift'
      @delay 25
      @key 'delete'
      @delay 25
  'cursor:way-up': ->
    # Same in Mac OS X and Mac OS X 10.5, but could also implement as Edit->Select All and then left/right.
    @key 'home', 'command'
  'cursor:way-down': ->
    @key 'end', 'command'
  'delete:way-left': ->
    @key 'left', 'command shift'
    @key 'delete'
  'selection:way-up': ->
    # Same in Mac OS X and Mac OS X 10.5
    @key 'home', 'shift command'
  'selection:way-down': ->
    # Same in Mac OS X and Mac OS X 10.5
    @key 'end', 'shift command'
  'text-manipulation:move-line-down': ->
    @openMenuBarPath(['Code', 'Move Line Down'])
  'text-manipulation:move-line-up': ->
    @openMenuBarPath(['Code', 'Move Line Up'])
  'selection:previous-occurrence': (input) ->
    if input?.value?
      term = input?.value
      @openMenuBarPath(['Edit', 'Find', 'Find...'])
      @delay 15
      @paste term
      @delay 25
      @openMenuBarPath(['Edit', 'Find', 'Find Previous / Move to Previous Occurrence'])
      @delay 25
      @key 'escape'
  'selection:next-occurrence': (input) ->
    if input?.value?
      term = input?.value
      @openMenuBarPath(['Edit', 'Find', 'Find...'])
      @delay 15
      @paste term
      @delay 25
      @openMenuBarPath(['Edit', 'Find', 'Find Next / Move to Next Occurrence'])
      @delay 25
      @key 'escape'
  'selection:next-selection-occurrence': ->
    if @getSelectedText()
      @openMenuBarPath(['Edit', 'Find', 'Find...'])
      @delay 15
      @openMenuBarPath(['Edit', 'Find', 'Find Next / Move to Next Occurrence'])
      @delay 15
      @key 'escape'
  'selection:previous-selection-occurrence': ->
    if @getSelectedText()
      @openMenuBarPath(['Edit', 'Find', 'Find...'])
      @delay 15
      @openMenuBarPath(['Edit', 'Find', 'Find Previous / Move to Previous Occurrence'])
      @delay 15
      @key 'escape'

pack.commands
  'intellij-complete':
    spoken: 'comply'
    description: 'Trigger completion.'
    action: ->
      if Scope.active('intellij')
        @openMenuBarPath(['Code', 'Completion', 'Basic'])
      else
        # using indirection for name, in case the name is redefined via changeSpoken
        @string pack._commands['intellij:intellij-complete'].spoken

  'intellij-smart-complete':
    spoken: 'schmaltz'
    repeatable: true
    description: 'Trigger smart completion.  Do it again to search deeper.'
    action: ->
      if Scope.active('intellij')
        # This works correctly when repeated!
        @openMenuBarPath(['Code', 'Completion', 'SmartType'])
      else
        @string pack._commands['intellij:intellij-smart-complete'].spoken

  'intellij-smart-finish':
    spoken: 'finagle'
    description: 'Smart finish.  Balances parens, braces, etc.'
    action: ->
      if Scope.active('intellij')
        @openMenuBarPath(['Edit', 'Complete Current Statement'])
      else
        @string pack._commands['intellij:intellij-smart-finish'].spoken

  'intellij-zoom-editor':
    spoken: 'idea zoom'
    description: 'Toggle maximizing editor'
    action: ->
      if Scope.active('intellij')
        @openMenuBarPath(['Window', 'Active Tool Window', 'Hide All Windows'])

  'intellij-find-usage':
    spoken: 'idea find usage'
    description: 'Find usages of current symbol'
    action: ->
      if Scope.active('intellij')
        @openMenuBarPath(['Edit', 'Find', 'Find Usages'])

  'intellij-refactor':
    spoken: 'idea reflector'
    description: 'Open refactor dialog'
    action: ->
      if Scope.active('intellij')
        @openMenuBarPath(['Refactor', 'Refactor This...'])

  'intellij-quick-fix':
    spoken: 'idea fix this'
    description: 'Open quick fix dialog'
    action: ->
      # 'Show intention actions' has no menu item!
      # Luckily, this is identical in both OS X keymaps, but added to settings just in case.
      if Scope.active('intellij')
        @key pack.settings().showIntentionActions...

  'intellij-quick-fix-next':
    spoken: 'idea fix next'
    description: 'Open quick fix dialog on next highlighted error'
    action: ->
      if Scope.active('intellij')
        @openMenuBarPath(['Navigate', 'Next Highlighted Error'])
        @delay 50
        @do 'intellij:intellij-quick-fix'

  'intellij-quick-fix-previous':
    spoken: 'idea fix previous'
    description: 'Open quick fix dialog on previous highlighted error'
    action: ->
      if Scope.active('intellij')
        @openMenuBarPath(['Navigate', 'Previous Highlighted Error'])
        @delay 50
        @do 'intellij:intellij-quick-fix'

  'intellij-go-to-declaration':
    spoken: 'decker'
    description: 'Go to declaration'
    # misspellings: ['jekyll', 'deco']
    action: ->
      if Scope.active('intellij')
        @openMenuBarPath(['Navigate', 'Declaration'])

  'intellij-go-to-implementation':
    spoken: 'idea implementers'
    description: 'Go to implementation(s)'
    action: ->
      if Scope.active('intellij')
        @openMenuBarPath(['Navigate', 'Implementation(s)'])

  'intellij-go-to-type-declaration':
    spoken: 'idea type'
    description: 'Go to type declaration'
    action: ->
      if Scope.active('intellij')
        @openMenuBarPath(['Navigate', 'Type Declaration'])

  'intellij-surround':
    spoken: 'idea surround'
    description: 'Open Surround With dialog.'
    action: ->
      if Scope.active('intellij')
        @openMenuBarPath(['Code', 'Surround With'])

  'intellij-generate':
    spoken: 'idea generate'
    description: 'Open Generate Code dialog.'
    action: ->
      if Scope.active('intellij')
        @openMenuBarPath(['Code', 'Generate...'])

  'intellij-decrease-code-blocks-selection':
    spoken: 'brakong'
    description: 'Decrease current selection to previous state'
    repeatable: true
    action: ->
      if Scope.active('intellij')
        @openMenuBarPath(['Edit', 'Shrink Selection'])
      else
        @string pack._commands['intellij:intellij-smart-complete'].spoken
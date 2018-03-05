# https://stackoverflow.com/questions/32895522/disable-copying-entire-line-when-nothing-is-selected-in-intellij

http = require 'http'

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

# Each IDE gets its own port, as otherwise you wouldn't be able
# to run two at the same time and switch between them.
# Note that MPS and IntelliJ ultimate will conflict...
portMapping = {
  'com.jetbrains.intellij': 8653
  'com.jetbrains.intellij.ce': 8654
  'com.jetbrains.AppCode': 8655
  'com.jetbrains.CLion': 8657
  'com.jetbrains.datagrip': 8664
  'com.jetbrains.goland': 8666
  'com.jetbrains.PhpStorm': 8662
  'com.jetbrains.pycharm': 8658
  'com.jetbrains.rubymine': 8661
  'com.jetbrains.WebStorm': 8663
  'com.google.android.studio': 8652
}

idea = (args...) ->
  command = args[0]
  if args.length == 2
    callback = args[1]
  else
    callback = console.log # XXX chatty
  port = portMapping[_a.currentApplication().bundleId]
  response = ""
  http.get({
    hostname: 'localhost',
    port: port,
    path: '/' + encodeURIComponent(command),
    agent: false
  }, (res) ->
    rawData = ''
    res.on 'data', (chunk) -> rawData += chunk
    res.on 'end', () -> callback rawData
  ).on 'error', (e) ->
    console.log "Error talking to intellij : " + e


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

Settings.darwin.applicationsThatNeedExplicitModifierPresses.push(
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
)

pack.implement {scope: 'intellij'},
  # Object package
  'object:duplicate': ->
    idea('action EditorDuplicate')
  'object:backward': ->
    idea('action Back')
  'object:forward': ->
    idea('action Forward')
  'object:refresh': ->
    # Synchronize.
    idea('action Synchronize')
  'object:next': ->
    # Next method?
    idea('action MethodDown')
  'object:previous': ->
    # Previous method?
    idea('action MethodUp')
  # Editor package
  'editor:move-to-line-number': (input) ->
    idea("goto " + input + " 0")
  'editor:toggle-comments': ->
    idea('action CommentByLineComment')
  'editor:expand-selection-to-scope': (input, context) ->
    idea('action EditorSelectWord')
    if context.chain?
      @delay 100  # Still needed?
  'editor:insert-from-line-number': (input) ->
    # store old clipboard
    clipboard = @getClipboard()
    currentPosition = position()
    # Jump to line (see above)
    idea("goto " + input + " 0")
    # Select line and copy: Command left, Shift command right, Cmd-C
    # Would a keymap ever be able to mess with this?
    # Yes, but the two OS X keymaps do not.
    @key 'right', 'command shift'
    @delay 50
    @copy()
    @delay 50
    # Jump to our exact original position:
    idea("goto " + currentPosition[0] + " " + currentPosition[1])
    # Paste.
    @paste()
    @delay 50
    # Restore clipboard
    @setClipboard(clipboard)
  'editor:open-command-pallet': ->
    idea("action GotoAction")
  'selection:block': ->  # Close to 'editor:expand-selection-to-indentation', but I dunno how that one is going to work.
    idea("action EditorCodeBlockStart")
    idea("action EditorCodeBlockEndWithSelection")
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
      idea("goto " + first + " 0")
      @key 'left', 'command'
      @delay 25
      while first < last
        @key 'down', 'shift'
        # @delay 15
        @openMenuBarPath(['Code', 'Folding', 'Expand'])
        # @delay 15
        first++
      @key 'right', 'command shift'
  'editor:extend-selection-to-line-number': (input) ->
    if input
      if @getSelectedText()
        @key 'escape'
      @openMenuBarPath(['Navigate', 'Line/Column...'])
      while not @getSelectedText()
        @delay 15
        console.log @getSelectedText()
      # console.log @getSelectedText()
      copied = _.split @getSelectedText(), ':'
      @key 'escape'
      @delay 10
      currentLineNumber = parseInt(copied[0])
      target = parseInt(input)
      distance = Math.abs(currentLineNumber - target)
      console.log currentLineNumber + ',' + target + ' Distance: ' + distance
      if distance > 30
        console.log 'Refusing to select a line that far away'
        return
      # console.log '' + copied + ', ' + target
      if currentLineNumber < target
        counter = currentLineNumber
        while counter < target
          @key 'down', 'shift'
          #@delay 10
          @openMenuBarPath(['Code', 'Folding', 'Expand'])
          #@delay 10
          counter++
        @key 'right', 'command shift'
      else
        counter = target
        while counter < currentLineNumber
          @key 'up', 'shift'
          #@delay 10
          @openMenuBarPath(['Code', 'Folding', 'Expand'])
          #@delay 10
          counter++
        @key 'left', 'command shift'
  'editor:select-line-number': (input) ->
    idea("goto " + input + " 0")
    @key 'right', 'command shift'
  'editor:move-to-line-number-and-way-left': (input) ->
    idea("goto " + input + " 0")
  'editor:move-to-line-number-and-way-right': (input) ->
    idea("goto " + input + " 9999")
  'editor:insert-under-line-number': (input) ->
    idea("goto " + input + " 9999")
    @key 'enter'
  'editor:list-projects': ->
    # Recent files, not projects.
    @openMenuBarPath(['View', 'Recent Files'])
  'delete:lines': (input) ->
    console.log Scope.active('intellij')
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
      idea("goto " + currentPosition[0] + " " + currentPosition[1])
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
    idea("action EditorTextStart")
  'cursor:way-down': ->
    idea("action EditorTextEnd")
  'delete:way-left': ->
    @key 'left', 'command shift'
    @key 'delete'
  'selection:way-up': ->
    idea("action EditorTextStartWithSelection")
  'selection:way-down': ->
    idea("action EditorTextEndWithSelection"
  'text-manipulation:move-line-down': ->
    idea("action MoveLineDown")
  'text-manipulation:move-line-up': ->
    idea("action MoveLineUp")
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
      @key 'Delete'
      @delay 10
      @paste term
      @delay 25
      # @openMenuBarPath(['Edit', 'Find', 'Find Next / Move to Next Occurrence'])
      # @delay 25
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
  'delete:partial-word': ->
    idea("action EditorDeleteToWordStartInDifferentHumpsMode")
  'delete:partial-word-forward': ->
    idea("action EditorDeleteToWordEndInDifferentHumpsMode")
  'window:new-tab': ->
    idea("action GotoClass")

pack.commands
  'intellij-complete':
    spoken: 'comply'
    description: 'Trigger completion.'
    action: ->
      if Scope.active('intellij')
        idea("action CodeCompletion")
      else
        # using indirection for name, in case the name is redefined via changeSpoken
        @string pack._commands['intellij:intellij-complete'].spoken

  'intellij-smart-complete':
    spoken: 'schmaltz'
    repeatable: true
    description: 'Trigger smart completion.  Do it again to search deeper.'
    action: ->
      if Scope.active('intellij')
        # This works correctly when repeated? XXX
        idea("action SmartTypeCompletion")
      else
        @string pack._commands['intellij:intellij-smart-complete'].spoken

  'intellij-smart-finish':
    spoken: 'finagle'
    description: 'Smart finish.  Balances parens, braces, etc.'
    action: ->
      if Scope.active('intellij')
        idea("action EditorCompleteStatement")
      else
        @string pack._commands['intellij:intellij-smart-finish'].spoken

  'intellij-zoom-editor':
    spoken: 'idea zoom'
    description: 'Toggle maximizing editor'
    action: ->
      if Scope.active('intellij')
        idea("action HideAllWindows")

  'intellij-find-usage':
    spoken: 'idea find usage'
    description: 'Find usages of current symbol'
    action: ->
      if Scope.active('intellij')
        idea("action FindUsages")

  'intellij-refactor':
    spoken: 'idea reflector'
    description: 'Open refactor dialog'
    action: ->
      if Scope.active('intellij')
        idea("action Refactorings.QuickListPopupAction")

  'intellij-quick-fix':
    spoken: 'idea fix this'
    description: 'Open quick fix dialog'
    action: ->
      # 'Show intention actions' has no menu item!
      # Luckily, this is identical in both OS X keymaps, but added to settings just in case.
      if Scope.active('intellij')
        idea("action ShowIntentionActions")

  'intellij-quick-fix-next':
    spoken: 'idea fix next'
    description: 'Open quick fix dialog on next highlighted error'
    action: ->
      if Scope.active('intellij')
        idea("action GotoNextError")
        idea("action ShowIntentionActions")
        

  'intellij-quick-fix-previous':
    spoken: 'idea fix previous'
    description: 'Open quick fix dialog on previous highlighted error'
    action: ->
      if Scope.active('intellij')
        idea("action GotoPreviousError")
        idea("action ShowIntentionActions")
        

  'intellij-go-to-declaration':
    spoken: 'decker'
    description: 'Go to declaration'
    # misspellings: ['jekyll', 'deco']
    action: ->
      if Scope.active('intellij')
        idea("action GotoDeclaration")
        

  'intellij-go-to-implementation':
    spoken: 'idea implementers'
    description: 'Go to implementation(s)'
    action: ->
      if Scope.active('intellij')
        idea("action GotoImplementation")

  'intellij-go-to-type-declaration':
    spoken: 'idea type'
    description: 'Go to type declaration'
    action: ->
      if Scope.active('intellij')
        idea("action GotoTypeDeclaration")

  'intellij-surround':
    spoken: 'idea surround'
    description: 'Open Surround With dialog.'
    action: ->
      if Scope.active('intellij')
        idea("action SurroundWith")

  'intellij-generate':
    spoken: 'idea generate'
    description: 'Open Generate Code dialog.'
    action: ->
      if Scope.active('intellij')
        idea("action Generate")

  'intellij-decrease-code-blocks-selection':
    spoken: 'brakong'
    description: 'Decrease current selection to previous state'
    repeatable: true
    action: ->
      if Scope.active('intellij')
        idea("action EditorUnSelectWord")

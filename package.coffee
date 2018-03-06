# https://stackoverflow.com/questions/32895522/disable-copying-entire-line-when-nothing-is-selected-in-intellij

http = require 'http'

pack = Packages.register
  name: 'intellij'
  description: 'Jetbrains IntelliJ IDEA (and friends) integration'

_a = global.Actions

# Each IDE gets its own port, as otherwise you wouldn't be able
# to run two at the same time and switch between them.
# Note that MPS and IntelliJ ultimate will conflict...
portMapping = {
  'com.jetbrains.intellij': 8653
  'com.jetbrains.intellij.ce': 8654
  'com.jetbrains.AppCode': 8655
  'com.jetbrains.CLion': 8657
  'com.jetbrains.datagrip': 8664
  'com.jetbrains.goland': 8659
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
    callback = (_) -> 0
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
    console.log "Error talking to intellij: " + port + " " + encodeURIComponent(command) + "\n" + e


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
  condition: (input, context) ->
    # We only want to use IntelliJ package if we're looking at the editor window
    # Dialogs should use basic handling.
    # Most dialogs have no title, but some do.
    windowTitle = @applescript 'tell application "System Events" to get name of first window of (first application process whose frontmost is true)'
    windowRole = @applescript 'tell application "System Events" to get subrole of first window of (first application process whose frontmost is true)'
    # However, the main editor windows always have a title like: 
    #   name [path] - file/path
    # Using the square bracket as a hueristic should do for now.
    if windowRole == "AXStandardWindow"
      if windowTitle and windowTitle.indexOf('[') != -1 
        true
      else
        # Go to line dialog, etc.
        false
    else
      # Completion dialog, etc.
      true

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
    idea 'action EditorSelectWord', (_) ->
      # if context.chain?
        # @delay 100  # Still needed?
  'editor:insert-from-line-number': (input) ->
    idea "clone " + input
  'editor:open-command-pallet': ->
    idea("action GotoAction")
  'selection:block': ->  # Close to 'editor:expand-selection-to-indentation', but I dunno how that one is going to work.
    idea "action EditorCodeBlockStart", (_) ->
      idea("action EditorCodeBlockEndWithSelection")
  'editor:insert-code-template': (args)->
    # XXX The intellij ones don't match up with expected template names.
    # Create templates matching VC?   Or make VC templates match intellij?
    # (or freeform...)
    idea "action InsertLiveTemplate", (_) ->
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
      idea("range " + first + " " + last)
  'editor:extend-selection-to-line-number': (input) ->
    if input
      idea("extend " + input)
  'editor:select-line-number': (input) ->
    idea "goto " + input + " 0", (_) ->
      idea "action EditorLineEndWithSelection"
  'editor:move-to-line-number-and-way-left': (input) ->
    idea("goto " + input + " 0")
  'editor:move-to-line-number-and-way-right': (input) ->
    idea("goto " + input + " 9999")
  'editor:insert-under-line-number': (input) ->
    idea "goto " + input + " 9999", (_) ->
      @key 'enter'
  'editor:list-projects': ->
    # Recent files, not projects.
    idea("action RecentFiles")
  'delete:lines': (input) ->
    if input
      idea "location", (originalLocationString) ->
        original = _.split originalLocationString, ' '
        currentLineNumber = parseInt(original[0])
        target = parseInt(input)
        if currentLineNumber > target
          currentLineNumber = currentLineNumber - 1 # To account for our line moving up.
        idea "goto " + input + " 0", (_) ->
          idea "action EditorDeleteLine", (_) ->
            idea "goto " + currentLineNumber + " " + original[1]
    else
      # snipline with no argument leaves an empty line.
      # With RPC:
      idea "action EditorLineEnd", (_) ->
        idea "action EditorDeleteToLineStart"

      # However, there are dialogs and other things which happen, and I need to know which to use!
      # @key 'right', 'command'
      # @delay 25
      # @key 'left', 'command shift'
      # @delay 25
      # @key 'delete'
      # @delay 25
  'cursor:way-up': ->
    idea("action EditorTextStart")
  'cursor:way-down': ->
    idea("action EditorTextEnd")
  'delete:way-left': ->
    idea "action EditorDeleteToLineStart"
  'delete:way-right': ->
    idea "action EditorDeleteToLineEnd"
  'selection:way-up': ->
    idea("action EditorTextStartWithSelection")
  'selection:way-down': ->
    idea("action EditorTextEndWithSelection")
  'text-manipulation:move-line-down': ->
    idea("action MoveLineDown")
  'text-manipulation:move-line-up': ->
    idea("action MoveLineUp")
  'selection:previous-occurrence': (input) ->
    if input?.value?
      term = input?.value
      idea("find prev " + term)
  'selection:next-occurrence': (input) ->
    if input?.value?
      term = input?.value
      idea("find next " + term)
  'selection:next-selection-occurrence': ->
    if @getSelectedText()
      idea("find next " + @getSelectedText())
  'selection:previous-selection-occurrence': ->
    if @getSelectedText()
      idea("find prev " + @getSelectedText())
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

  'intellij-show-error':
    spoken: 'idea error description'
    description: 'Show error description at cursor'
    action: ->
      if Scope.active('intellij')
        idea("action ShowErrorDescription")

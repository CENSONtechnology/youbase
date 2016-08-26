_ = require 'lodash'
bs = require 'bs58check'
defer = require 'when'
deferObject = require 'when/keys'

class Definition
  constructor: (@custodian, definition) ->
    throw Error('Custodian is required') unless @custodian?
    if !(@ instanceof Definition) then return new Definition(@custodian, definition)
    else if (definition instanceof Definition) then return definition
    else if (typeof definition is 'object') then @_definition = defer(definition)
    else if (typeof definition is 'string') then @_definition = @custodian.data.get(bs.decode(definition))
    else throw Error("Invalid definition #{typeof definition}: #{definition}")

  child: (key) -> @children().then(children) -> Definition(@custodian, children[key])

  children: ->
    @_children ?= @_definition.then (definition) ->
      deferObject.map (definition?.children ? {}), (child) ->
        Definition(@custodian, child).save()
        .then (hash) -> bs.encode(hash)

  get: (key) ->
    if key? then @get().then (definition) -> definition[key]
    else
      @_data ?= @_definition.then (definition) =>
        @children().then (children) =>
          permissions: definition?.permissions ? 'public'
          meta: definition?.meta ? {}
          form: definition?.form ? {}
          schema: definition?.schema ? {}
          children: children

  save: -> @custodian.data.put(@get())

exports = module.exports = Definition

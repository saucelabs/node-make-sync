###
# node-make-sync
# Copyright(c) 2012 Seb Vincent
# MIT Licensed
###

require('fibers');        
Future = require 'fibers/future'
wait = Future.wait
{Options} = require '../lib/options'


_callSync = (f, options , args...) ->   
  # making sure the returns follow the
  # usual callback rule
  fWithErr = (callback) ->
    f.apply this, [ 
      args..., (res...) ->
        callback null,res
      ]
  wrappedf = Future.wrap fWithErr
  res = wrappedf.apply this
  wait(res)
  res = res.get()
  switch options?.errorType()
    when 'callback'
      err = res[0]
      res = res[1..]
    when 'none'
      # nothing to do
    else
      # returns res or [err, res...]. Works well when there is no error,
      # otherwise the client will have to deal with the error.
      if res.length > 1
        res = res[1..] if not res[0]?
  if err? then throw new Error err
  switch res.length
     when 0 then return undefined
     when 1 then return res[0]
     else return res 
  
# return a function wich:
#   - uses fibers when the done callback is not detected.
#   - otherwise calls the original function
makeFuncSync = (f, options, key) ->

  mode = options.mode()
  numOfParams = options.numOfParams key
  [prepareCall] = []  
  switch mode[0]
    when 'sync' then prepareCall = (args...) -> ['sync',args]
    when 'async' then prepareCall = (args...) -> ['async',args]
    when 'mixed'
      switch mode[1]
        when 'fibers' then prepareCall = (args...) -> 
          if Fiber.current? then ['sync',args] else ['async',args] 
        when 'args'
          # move done to args when num of args too small, or if done is the
          # wrong type
          prepareCall = (args..., done) ->
            if numOfParams? and done? and args.length < numOfParams
              args.push done
              done = undefined
            if done? and typeof(done) isnt 'function'
              args.push done    
              done = undefined
            if done
              ['async',args.concat [done]]
            else
              ['sync',args]

  (args...) ->
    [callMode,args] = prepareCall args...    
    switch callMode
      when 'sync' then _callSync.apply this, [f, options, args...]
      when 'async' then f.apply this, [args...]

# apply makesync on all the object functions
makeObjSync = (obj, options) ->
  for k, v of obj when typeof v is 'function'
    if options.isIncluded k
      vSync = makeFuncSync v, options, k
      obj[k] = vSync
  obj


# call the approriate makeSync method depending on object type
makeSync = (target, _options) ->
  options = new Options(_options)
  switch typeof target
    when 'function' then makeFuncSync target, options
    when 'object' then makeObjSync target, options

# open a sync block
sync = (f) ->
  Fiber ->  
    do f
  .run()

exports.Sync = sync
exports.MakeSync = makeSync  
exports.MakeObjSync = makeObjSync
exports.MakeFuncSync = makeFuncSync

exports.sync = sync
exports.makeSync = makeSync  
exports.makeObjSync = makeObjSync
exports.makeFuncSync = makeFuncSync

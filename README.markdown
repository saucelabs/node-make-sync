# node-make-sync

This module uses  [node-fibers](http://github.com/laverdet/node-fibers) to transform asynchronous functions into 
synchronous ones. The asynchronous function must have a 'done' callback as the last arg, and 
must return result in the form 'done(res)' or 'done(err, res)'

The main commands are:

*   MakeSync to synchronize a function or object.
*   Sync to start a sync environment (starts a fiber).

When applied to an object, MakeSync patches all the object methods by default. 
It is also possible to pass some options to be more specific.

The following modes may be used to to make function synchronous (see description
further down):
   - sync (default)
   - async
   - mixed-args (default 'mixed')
   - mixed-fibers
   
## install
```
npm install node-make-sync
```

## usage (coffeescript)

### simple example

```coffeescript
{Sync, MakeSync} = require 'node-make-sync'

f = (a,b,done) ->
  res = a+b
  done null, res

# making synchronous 
f = MakeSync f

# sync call
Sync ->
  res = f 1, 2
  console.log "sync ->", res 

obj = 
  f: (a,b,done) ->
    res = a+b
    done null, res

# making synchronous
MakeSync obj

# sync call  
Sync ->
  res = obj.f 1, 2
  console.log "obj sync ->", res   
```

## modes

### sync (default)
```coffeescript
f = MakeSync f
# or
f = MakeSync f, {mode:'sync'}
```
This mode assumes that the function is always called in sync mode within a 
fiber, so that the 'done' callback is never there. (ie if there is a function
at the end it will assume this is a function argument and add it own callback)

### async
```coffeescript
f = MakeSync f, {mode:'async'}
```
This mode assumes that the function is always called in asynchronous mode, 
so doesn't change the function behaviour. (probably not useful in most case)  

### mixed-args (default mixed)
```coffeescript
f = MakeSync f, {mode:'mixed'}
# or
f = MakeSync f, {mode:['mixed', 'args']}
```
This mode uses the function arguments to determine wether it needs
to be called synchronously or asynchronously. When the last 
argument is a function, MakeSync assume the last argument is the 'done' callback. 
There may be some issues when using other function arguments. Please refer 
to the section below.

#### fixed numbers of args /  function arguments
This only applies when using the mixed-args mode and calling the function sychronously.

There are 2 strategies to resolve the confusion between the 'done' callback and other
function argument, when those are passed at the end of the argument list:

* use undefined as the last argument 
* pass the number of arguments expected (excluding the callback) to MakeSync.

```coffeescript
{Sync, MakeSync} = require 'node-make-sync'

f = (a,b, _g, done) ->
  res = a + b + _g()
  done null, res

g = -> 10

# synchronizing (not using a fixed number of arg)  
f1 = MakeSync f, {mode:['mixed', 'args']}

Sync ->
  try f1 1, 2, g catch error 
    console.log "f1 throws" # thinks that g is the callback

  res = f1 1, 2, g, undefined # ok when passing undefined at the end 
  console.log "sync ->", res 

# passing a fixed number of args 
f2 = MakeSync f, {mode:['mixed','args'], num_of_args: 3}

Sync ->
  res = f2 1, 2, g # it works 
  console.log "sync ->", res 
```

### mixed-fibers
```coffeescript
f = MakeSync f, {mode: ['mixed','fibers']}
```
When using this mode, MakeSync checks wether a fiber is currently available,
using 'Fiber.current', and uses the sync or async mode accordingly.

## options when calling on objects  
By default, when calling MakeSync on an object,  MakeSync is called on all its 
functions and no num_of_args argument is passed. However, it is possible to 
pass inclusion and exclusion lists, to specify num_of_args on a per function basis
and the MakeSync mode globally.

```coffeescript
{Sync, MakeSync} = require 'node-make-sync'

class Obj
  f1: (done) -> done null, 1,
  f2: (done) -> done null, 2,
  _f: (done) -> done null, 3,
  f3: (_g, done) -> done null, 4 + _g(),
  f4: (_g, done) -> done null, 5 + _g(),

g = -> 10

# all the function are included by default, 
# then some are specifically excluded.
options =
  mode: ['mixed', 'args']
  exclude: ['f1', /^_/]
  num_of_args:
    f4:1

obj = new Obj
MakeSync obj, options

Sync ->
  try obj.f1() catch error then console.log "f1 throws" # f1 was excluded  

  console.log 'f2 returns', obj.f2() # OK, not in the exclude list
  
  try obj._f() catch error then console.log "_f throws" # _f was excluded
  
  try obj.f3 g catch error 
    console.log "f3 throws" # num_of_args not set 
  
  console.log 'f4 returns', obj.f4 g # OK, num_of_args was set


# all the function are excluded 
# then some are specifically included.
options = 
  mode: 'sync'
  exclude: '*'
  include: ['f1', 'f3']

obj = new Obj
MakeSync obj, options

Sync ->
  console.log '\nf1 returns', obj.f1() # OK, f1 was included
  
  try obj.f2() catch error then console.log "f2 throws" # f2 was excluded
  
  console.log 'f3 returns', obj.f3 g # OK, f3 was included
  
# exclude can also accept a simple string or a regex
options1 = exclude: 'f1'
options2 = exclude: /^_/
```



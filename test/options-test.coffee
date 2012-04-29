should = require 'should'
{Options} = require '../lib/options'

describe "options", ->

  describe "isIncluded", ->

    describe "default", ->  
      it "include all", (done) ->
        options = new Options()
        res = (options.isIncluded 'f').should.be.ok
        done()

    describe "* rule", ->
      it "exclude", (done) ->
        options = new Options \
        {
          exclude: '*' 
        }
        (options.isIncluded 'f').should.not.be.ok
        done()
      it "include", (done) ->
        options = new Options \
        { 
          exclude: '*'
          include: '*'
        }
        (options.isIncluded 'f').should.be.ok
        done()

    describe "regex rule", ->
      it "exclude", (done) ->
        options = new Options \
        {
          exclude: /^_/
        }
        (options.isIncluded 'f').should.be.ok
        (options.isIncluded '_f').should.not.be.ok      
        done()
      it "include", (done) ->
        options = new Options \
        { 
          exclude: '*'
          include: /^f/
        }
        (options.isIncluded 'f').should.be.ok
        (options.isIncluded 'g').should.not.be.ok
        done()
    
    describe "string rule", ->
      it "exclude", (done) ->
        options = new Options \
        {
          exclude: '_f'
        }
        (options.isIncluded 'f').should.be.ok
        (options.isIncluded 'f_f').should.be.ok
        (options.isIncluded '_f').should.not.be.ok      
        done()
      it "include", (done) ->
        options = new Options \
        { 
          exclude: '*'
          include: 'f'
        }
        (options.isIncluded 'f').should.be.ok
        (options.isIncluded 'fff').should.not.be.ok
        (options.isIncluded 'g').should.not.be.ok
        done()
    
    describe "array", ->
      it "exclude", (done) ->
        options = new Options \
        { 
          exclude: [/^_/,'g']
        }
        (options.isIncluded 'f').should.be.ok
        (options.isIncluded '_f').should.not.be.ok
        (options.isIncluded 'g').should.not.be.ok      
        done()
      it "include", (done) ->
        options = new Options \
        { 
          exclude: '*'
          include: ['g',/^_/]
        }
        (options.isIncluded 'f').should.not.be.ok
        (options.isIncluded 'g').should.be.ok
        (options.isIncluded '_f').should.be.ok
        done()
  
  describe "numOfParams", ->
    it "function mode", (done) ->
      options = new Options \
      { 
        num_of_args: 5
      }        
      options.numOfParams().should.equal 5    
      (options.numOfParams undefined).should.equal 5    
      done()
    it "object mode", (done) ->
      options = new Options \
      { 
        num_of_args:
          f: 5
      }        
      (options.numOfParams 'f').should.equal 5    
      should.not.exist options.numOfParams 'g'
      done()

  describe "errorType", ->
    it "function mode", (done) ->
      options = new Options \
      { 
        error_type: 'callback'
      }        
      options.errorType().should.equal 'callback'    
      done()

  describe "mode", ->
    test = (mode,expected, label) ->
      label = "#{mode}" unless label?      
      it label, (done) ->
        options = new Options {} unless mode?
        options = new Options {mode: mode} if mode?                
        options.mode().should.eql expected
        done()    
    test(undefined, ['sync'], 'default')    
    test(['sync'], ['sync'])    
    test('sync', ['sync'], 'sync (string)' )    
    test(['sync','args'], ['sync'])    
    test(['mixed'], ['mixed','args'])    
    test('mixed', ['mixed','args'], 'mixed (string)')    
    test(['async'], ['async'])    
    test('async', ['async'], 'async (string)')    
    test(['async','args'], ['async'])    
    test(['sync','mixed'], ['mixed','args'])    
    test(['mixed','fibers'], ['mixed','fibers'])    
    test(['mixed','fibers','args'], ['mixed','args'])    
    test(['mixed','fibers','args','sync'], ['sync'])    

        
      
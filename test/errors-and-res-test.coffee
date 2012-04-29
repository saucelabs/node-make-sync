should = require 'should'
{Sync, MakeSync} = require('../lib/make-sync')
  
describe "sync", ->
  
  describe "error with error_type: 'callback'", ->
    it "should throw Shit", (done) ->
      f = (done) -> done "Shit happens!"
      syncF = MakeSync f, {error_type: 'callback'}
      Sync ->
        (-> syncF()).should.throw(/Shit/) 
        done()

  describe "normal result with error_type: 'none'", ->
    it "expect Shit", (done) ->
      f = (done) -> done "Shit happens!", "Shit happens again!"
      syncF = MakeSync f, {error_type: 'none'}
      Sync ->
        res = syncF()
        for i in [0,1]
          should.exist res[i].match /Shit/
        done()

  describe "single result without error_type specified", ->
    it "expect Shit", (done) ->
      f = (done) -> done "Shit happens!"
      syncF = MakeSync f 
      Sync ->
        res = syncF()
        should.exist res.match /Shit/
        done()

  describe "null error + result without error_type specified", ->
    it "expect Shit", (done) ->
      f = (done) -> done null, "Shit happens!"
      syncF = MakeSync f 
      Sync ->
        res = syncF()
        should.exist res.match /Shit/
        done()

  describe "error + result without error_type specified", ->
    it "let client handle Shit", (done) ->
      f = (done) -> done "Shit happens!", "Shit happens agains!"
      syncF = MakeSync f 
      Sync ->
        res = syncF()
        for i in [0,1]
          should.exist res[i].match /Shit/
        done()

  describe "single result", ->
    it "should return one cake", (done) ->
      f = (done) -> done null, "a cake"
      syncF = MakeSync f, {error_type: 'callback'}
      Sync ->
        res = syncF() 
        res.should.equal "a cake"
        done()

  describe "multiple result", ->
    it "should return three cakes", (done) ->
      f = (done) -> done null, "a cake", "a cake", "a cake" 
      syncF = MakeSync f, {error_type: 'callback'}
      Sync ->
        res = syncF() 
        res[i].should.equal "a cake" for i in [0..2]
        done()

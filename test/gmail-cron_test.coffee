expect = require('chai').expect

Robot       = require('hubot/src/robot')  
TextMessage = require('hubot/src/message').TextMessage

brainKeys = require('./../configs/brain_key.json')
#
# google-oauth
# Reference Hubot to Mocha. http://devlog.forkwell.com/2014/10/28/testable-hubot-tdddetesutowoshu-kinagarabotwozuo-ru
#/
describe 'google-gmail-cron', ->
  robot   = null
  user    = null
  adapter = null

  beforeEach (done) ->
    robot = new Robot(null, 'mock-adapter', false, 'hubot')

    robot.adapter.on 'connected', ->
      require('../scripts/gmail-cron')(robot)
      user = robot.brain.userForId '1',
        name: 'mocha'
        room: '#mocha'
      adapter = robot.adapter
      robot.brain.set(brainKeys.tokens, { accessToken: process.env.GOOGLE_ACCESS_TOKEN, refreshToken: process.env.GOOGLE_REFRESH_TOKEN })
      done()
    robot.run()

  afterEach -> robot.shutdown()

  #
  # Hubot google oauth scope help
  #
  describe 'responds "google gmail set notify"', ->
    describe 'args is empty', ->
      it 'response is not found labelName', (done) ->
        adapter.on 'reply', (envelope, strings) ->
          expect(strings[0]).to.match(/^not found labelName/)
          done()

        adapter.receive(new TextMessage(user, 'Hubot google gmail set notify labelName:'))

    describe 'args labelName not exists labelName', ->
      it 'response is has not labelName', (done) ->
        adapter.on 'reply', (envelope, strings) ->
          expect(strings[0]).to.match(/^has not labelName. \[labelName : hoge\]/)
          done()

        adapter.receive(new TextMessage(user, 'Hubot google gmail set notify labelName:hoge'))

    describe 'args labelName exists labelName', ->
      it 'response is not eixsts labelName', (done) ->
        adapter.on 'reply', (envelope, strings) ->
          expect(strings[0]).to.match(/^add notify labelName\[CATEGORY_SOCIAL\]/)
          done()

        adapter.receive(new TextMessage(user, 'Hubot google gmail set notify labelName:CATEGORY_SOCIAL'))

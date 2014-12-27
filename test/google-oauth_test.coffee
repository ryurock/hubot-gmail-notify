expect = require('chai').expect

Robot       = require('hubot/src/robot')  
TextMessage = require('hubot/src/message').TextMessage

describe 'google-oauth', ->
  robot   = null
  user    = null
  adapter = null

  beforeEach (done) ->
    robot = new Robot(null, 'mock-adapter', false, 'hubot')

    robot.adapter.on 'connected', ->
      #require('../scripts/example')(robot)
      require('../scripts/google-oauth')(robot)
      user = robot.brain.userForId '1',
        name: 'mocha'
        room: '#mocha'
      adapter = robot.adapter
      done()
    robot.run()

  afterEach -> robot.shutdown()

  #
  # Hubot google oauth scope help
  #
  it 'responds "google oauth Authorizing scope help"', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(envelope.user.name).to.equal('mocha')
      expect(strings[0]).to.match(/^Google Apis Authorizing OAuth2 scope help./)
      done()

    adapter.receive(new TextMessage(user, 'Hubot google oauth scope help'))

  #
  # Hubot google oauth generate auht url
  #
  it 'responds failed. "google oauth generate auth url" because process.env.HUBOT_GOOGLE_CLIENT_ID not setting', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.equal('google project required. client Id hubot cli use HUBOT_GOOGLE_CLIENT_ID={client id}')
      done()

    delete process.env.HUBOT_GOOGLE_CLIENT_ID
    delete process.env.HUBOT_GOOGLE_CLIENT_SECRET
    delete process.env.HUBOT_GOOGLE_REDIRECT_URL
    adapter.receive(new TextMessage(user, 'Hubot google oauth generate auth url'))

  it 'responds failed. "google oauth generate auth url" because process.env.HUBOT_GOOGLE_CLIENT_SECRET not setting', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.equal('google project required. client Secret hubot cli use HUBOT_GOOGLE_CLIENT_SECRET={client secret}')
      done()

    process.env.HUBOT_GOOGLE_CLIENT_ID     = 'xxxxxxxxxxxxxx'
    delete process.env.HUBOT_GOOGLE_CLIENT_SECRET
    delete process.env.HUBOT_GOOGLE_REDIRECT_URL
    adapter.receive(new TextMessage(user, 'Hubot google oauth generate auth url'))

  it 'responds failed. "google oauth generate auth url" because process.env.HUBOT_GOOGLE_REDIRECT_URL not setting', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.equal('google project required. Redirect Url hubot cli use HUBOT_GOOGLE_REDIRECT_URL={redirect url}')
      done()

    process.env.HUBOT_GOOGLE_CLIENT_ID     = 'xxxxxxxxxxxxxx'
    process.env.HUBOT_GOOGLE_CLIENT_SECRET = 'yyyyyyyyyyyyyy'
    delete process.env.HUBOT_GOOGLE_REDIRECT_URL
    adapter.receive(new TextMessage(user, 'Hubot google oauth generate auth url'))

  it 'responds success. "google oauth generate auth url"', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.match(/^Auth URL/)
      done()

    process.env.HUBOT_GOOGLE_CLIENT_ID     = 'xxxxxxxxxxxxxx'
    process.env.HUBOT_GOOGLE_CLIENT_SECRET = 'yyyyyyyyyyyyyy'
    process.env.HUBOT_GOOGLE_REDIRECT_URL  = 'urn:ietf:wg:oauth:2.0:oob'

    adapter.receive(new TextMessage(user, 'Hubot google oauth generate auth url'))

  #
  # Hubot google oauth set token
  #
  it 'responds failed. "google oauth set token <code>" because process.env.HUBOT_GOOGLE_CLIENT_ID not setting', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.equal('google project required. client Id hubot cli use HUBOT_GOOGLE_CLIENT_ID={client id}')
      done()

    delete process.env.HUBOT_GOOGLE_CLIENT_ID
    delete process.env.HUBOT_GOOGLE_CLIENT_SECRET
    delete process.env.HUBOT_GOOGLE_REDIRECT_URL
    adapter.receive(new TextMessage(user, 'Hubot google oauth set token hoge'))

  it 'responds failed. "google oauth set token <code>" because process.env.HUBOT_GOOGLE_CLIENT_SECRET not setting', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.equal('google project required. client Secret hubot cli use HUBOT_GOOGLE_CLIENT_SECRET={client secret}')
      done()

    process.env.HUBOT_GOOGLE_CLIENT_ID     = 'xxxxxxxxxxxxxx'
    delete process.env.HUBOT_GOOGLE_CLIENT_SECRET
    delete process.env.HUBOT_GOOGLE_REDIRECT_URL
    adapter.receive(new TextMessage(user, 'Hubot google oauth set token hoge'))

  it 'responds failed. "google oauth set token <code>" because process.env.HUBOT_GOOGLE_REDIRECT_URL not setting', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.equal('google project required. Redirect Url hubot cli use HUBOT_GOOGLE_REDIRECT_URL={redirect url}')
      done()

    process.env.HUBOT_GOOGLE_CLIENT_ID     = 'xxxxxxxxxxxxxx'
    process.env.HUBOT_GOOGLE_CLIENT_SECRET = 'yyyyyyyyyyyyyy'
    delete process.env.HUBOT_GOOGLE_REDIRECT_URL
    adapter.receive(new TextMessage(user, 'Hubot google oauth set token hoge'))

  it 'responds failed. "google oauth set token <code>" because process.env.REDIS_URL not setting', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.equal('hubot redis brain not using. hubot cli REDIS_URL=redis://127.0.0.1:6379/hubot ./bin/hubot')
      done()

    process.env.HUBOT_GOOGLE_CLIENT_ID     = 'xxxxxxxxxxxxxx'
    process.env.HUBOT_GOOGLE_CLIENT_SECRET = 'yyyyyyyyyyyyyy'
    process.env.HUBOT_GOOGLE_REDIRECT_URL  = 'urn:ietf:wg:oauth:2.0:oob'
    adapter.receive(new TextMessage(user, 'Hubot google oauth set token hoge'))

  it 'responds failed. "google oauth set token <code>" because code empty', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.equal("oauth code not found. Please try 'hubot google oauth generate auth url")
      done()

    process.env.HUBOT_GOOGLE_CLIENT_ID     = 'xxxxxxxxxxxxxx'
    process.env.HUBOT_GOOGLE_CLIENT_SECRET = 'yyyyyyyyyyyyyy'
    process.env.HUBOT_GOOGLE_REDIRECT_URL  = 'urn:ietf:wg:oauth:2.0:oob'
    process.env.REDIS_URL                   = 'redis://127.0.0.1:6379/hubot'

    adapter.receive(new TextMessage(user, 'Hubot google oauth set token '))

  #
  # Hubot google oauth set scope
  #
  it 'responds failed. "google oauth set scope <scope>" because process.env.HUBOT_GOOGLE_CLIENT_ID not setting', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.equal('google project required. client Id hubot cli use HUBOT_GOOGLE_CLIENT_ID={client id}')
      done()

    delete process.env.HUBOT_GOOGLE_CLIENT_ID
    delete process.env.HUBOT_GOOGLE_CLIENT_SECRET
    delete process.env.HUBOT_GOOGLE_REDIRECT_URL
    delete process.env.REDIS_URL
    adapter.receive(new TextMessage(user, 'Hubot google oauth set scope hoge'))

  it 'responds failed. "google oauth set scope <scope>" because process.env.HUBOT_GOOGLE_CLIENT_SECRET not setting', (done) ->
    adapter.on 'reply', (envelope, strings) ->
      expect(strings[0]).to.equal('google project required. client Secret hubot cli use HUBOT_GOOGLE_CLIENT_SECRET={client secret}')
      done()

    process.env.HUBOT_GOOGLE_CLIENT_ID     = 'xxxxxxxxxxxxxx'
    delete process.env.HUBOT_GOOGLE_CLIENT_SECRET
    delete process.env.HUBOT_GOOGLE_REDIRECT_URL
    adapter.receive(new TextMessage(user, 'Hubot google oauth set scope hoge'))


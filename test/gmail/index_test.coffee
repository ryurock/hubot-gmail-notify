expect = require('chai').expect
should = require('should')

#
# gmail
#
describe 'gmail', ->
  Gmail = require('../../src/gmail')

  clientId     = process.env.GOOGLE_CLIENT_ID
  clientSecret = process.env.GOOGLE_CLIENT_SECRET
  redirectUrl  = process.env.GOOGLE_REDIRECT_URL
  tokens       = { accessToken: process.env.GOOGLE_ACCESS_TOKEN, refreshToken: process.env.GOOGLE_REFRESH_TOKEN }

  beforeEach (done) -> done()
  afterEach ->

  describe 'configure', () ->
    describe 'opts validate', () ->

      it 'configure args opts string is Throw Error', (done) ->
        ( () -> Gmail.configure('hoge') ).should.throw()
        done()

      it 'configure args opts hash clientId is not exits Throw Error', (done) ->
        ( () -> Gmail.configure({ hoge : 'fuga'}) ).should.throw()
        done()

      it 'configure args opts hash clientSecret is not exits Throw Error', (done) ->
        ( () -> Gmail.configure({ clientId : clientId}) ).should.throw()
        done()

      it 'configure args opts hash redirectUrl is not exits Throw Error', (done) ->
        ( () -> Gmail.configure({ clientId : clientId, clientSecret: clientSecret}) ).should.throw()
        done()

      it 'configure args opts hash tokens is not exits Throw Error', (done) ->
        ( () -> Gmail.configure({ clientId : clientId, clientSecret: clientSecret, redirectUrl: redirectUrl }) ).should.throw()
        done()

      it 'exception does not occur if the hash is everything', (done) ->
        ( () -> Gmail.configure({ clientId : clientId, clientSecret: clientSecret, redirectUrl: redirectUrl, tokens: tokens }) ).should.not.throw()
        done()

    describe 'opts setting vars check', () ->
      it 'is possible to get the clientId after you run the configure', (done) ->
        Gmail.configure({ clientId : clientId, clientSecret: clientSecret, redirectUrl: redirectUrl, tokens: tokens })
        expect(Gmail.clientId).to.equal(clientId)
        done()

      it 'is possible to get the clientSecret after you run the configure', (done) ->
        Gmail.configure({ clientId : clientId, clientSecret: clientSecret, redirectUrl: redirectUrl, tokens: tokens })
        expect(Gmail.clientSecret).to.equal(clientSecret)
        done()

      it 'is possible to get the redirectUrl after you run the configure', (done) ->
        Gmail.configure({ clientId : clientId, clientSecret: clientSecret, redirectUrl: redirectUrl, tokens: tokens })
        expect(Gmail.redirectUrl).to.equal(redirectUrl)
        done()

      it 'is possible to get the tokens after you run the configure', (done) ->
        Gmail.configure({ clientId : clientId, clientSecret: clientSecret, redirectUrl: redirectUrl, tokens: tokens })
        expect(Gmail.tokens).to.equal(tokens)
        done()

  describe 'oAuthClient', () ->
    describe 'response', () ->
      it 'object', (done) ->
        expect(Gmail.oAuthClient()).to.be.an('object')
        done()


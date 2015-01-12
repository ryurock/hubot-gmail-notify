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

  describe 'findLabelsList', () ->
    describe 'no args', () ->
      it 'throw Error', (done) ->
        ( () -> Gmail.findLabelsList() ).should.throw()
        done()

    describe 'before configure not execute', () ->
      it 'response status is unknownError', (done) ->
        Gmail.clientId = ''
        Gmail.clientSecret = ''
        Gmail.redirectUrl = ''
        Gmail.tokens = {}
        Gmail.findLabelsList('hoge', (status, message) ->
          expect(status.unknownError).to.be.true
          done()
        )

    describe 'the tag does not exist', () ->
      it 'response status is hasNotLabelName', (done) ->
        Gmail.configure({ clientId : clientId, clientSecret: clientSecret, redirectUrl: redirectUrl, tokens: tokens })
        Gmail.findLabelsList('hoge', (status, response) ->
          #console.log status
          expect(status.hasNotLabelName).to.be.true
          done()
        )

    describe 'the tag does exist', () ->
      it 'response status is null', (done) ->
        Gmail.configure({ clientId : clientId, clientSecret: clientSecret, redirectUrl: redirectUrl, tokens: tokens })
        Gmail.findLabelsList('CATEGORY_SOCIAL', (status, response) ->
          expect(status).to.be.null
          done()
        )
      

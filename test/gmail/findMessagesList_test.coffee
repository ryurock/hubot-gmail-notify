chai      = require('chai')
expect    = require('chai').expect
should    = require('should')
sinon     = require('sinon')
sinonChai = require('sinon-chai')
chai.use(sinonChai)

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

  describe 'findMessagesList', () ->
    describe 'no args', () ->
      it 'throw Error', (done) ->
        ( () -> Gmail.findMessagesList() ).should.throw()
        done()

    describe 'args apiParams is string', () ->
      it 'throw Error', (done) ->
        ( () -> Gmail.findMessagesList('string') ).should.throw()
        done()

    describe 'before configure not execute', () ->
      it 'response status is unknownError', (done) ->
        Gmail.clientId = ''
        Gmail.clientSecret = ''
        Gmail.redirectUrl = ''
        Gmail.tokens = {}
        Gmail.findMessagesList({limit: 5}, (status, message) ->
          expect(status.unknownError).to.be.true
          done()
        )

    describe 'If the optional parameter labelsId does not exist', () ->
      it 'response is error status does not exists', (done) ->
        Gmail.configure({ clientId : clientId, clientSecret: clientSecret, redirectUrl: redirectUrl, tokens: tokens })
        Gmail.findMessagesList({limit: 5}, (status, response) ->
          expect(status).to.be.null
          done()
        )

    describe 'If the optional parameter labelsId does exist', () ->
      describe 'apiParams.labels is wrong parametor', () ->
        it 'response status is isApiError', (done) ->
          Gmail.configure({ clientId : clientId, clientSecret: clientSecret, redirectUrl: redirectUrl, tokens: tokens })
          Gmail.findMessagesList({limit: 5, labels: {id: [100000000]}}, (status, response) ->
            expect(status.isApiError).to.be.true
            done()
          )

      describe 'apiParams.labels is correct parametor', () ->
        it 'response is error status does not exists', (done) ->
          Gmail.configure({ clientId : clientId, clientSecret: clientSecret, redirectUrl: redirectUrl, tokens: tokens })
          Gmail.findMessagesList({limit: 5, labels: {id: 'CATEGORY_SOCIAL'}}, (status, response) ->
            expect(status).to.be.null
            done()
          )

      describe 'apiParams.labels does not exist labelsId', () ->
        it 'response status is isApiError', (done) ->
          Gmail.configure({ clientId : clientId, clientSecret: clientSecret, redirectUrl: redirectUrl, tokens: tokens })
          Gmail.findMessagesList({limit: 5, labels: {id: 100000000}}, (status, response) ->
            expect(status.isApiError).to.be.true
            done()
          )


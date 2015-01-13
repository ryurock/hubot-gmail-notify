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
  async = require('async')

  clientId     = process.env.GOOGLE_CLIENT_ID
  clientSecret = process.env.GOOGLE_CLIENT_SECRET
  redirectUrl  = process.env.GOOGLE_REDIRECT_URL
  tokens       = { accessToken: process.env.GOOGLE_ACCESS_TOKEN, refreshToken: process.env.GOOGLE_REFRESH_TOKEN }

  beforeEach (done) -> done()
  afterEach ->

  describe 'findMessagesGet', () ->
    describe 'no args', () ->
      it 'throw Error', (done) ->
        ( () -> Gmail.findMessagesGet() ).should.throw()
        done()

    describe 'args messageIds is string', () ->
      it 'throw Error', (done) ->
        ( () -> Gmail.findMessagesGet('string') ).should.throw()
        done()

    describe 'before configure not execute', () ->
      it 'response status is unknownError', (done) ->
        Gmail.clientId = ''
        Gmail.clientSecret = ''
        Gmail.redirectUrl = ''
        Gmail.tokens = {}
        Gmail.findMessagesGet([ { id: 'hoge', threadId: 'fuga' } ], (status, message) ->
          expect(status.unknownError).to.be.true
          done()
        )

    describe 'If args messageIds does exist', () ->
      describe 'messageIds is wrong parametor', () ->
        it 'response status is isApiError', (done) ->
          Gmail.configure({ clientId : clientId, clientSecret: clientSecret, redirectUrl: redirectUrl, tokens: tokens })
          Gmail.findMessagesGet([ { id: 'hoge', threadId: 'fuga' } ], (status, response) ->
            expect(status.isApiError).to.be.true
            done()
          )

      describe 'messageIds is correct parametor', () ->
        it 'response is error status does not exists', (done) ->
          Gmail.configure({ clientId : clientId, clientSecret: clientSecret, redirectUrl: redirectUrl, tokens: tokens })
          Gmail.findMessagesList({limit: 5, labels: {id: 'CATEGORY_SOCIAL'}}, (status, response) ->
            Gmail.findMessagesGet(response, (status, response) ->
              expect(status).to.be.null
              done()
            )
          )

        it 'response has title date snippet', (done) ->
          Gmail.configure({ clientId : clientId, clientSecret: clientSecret, redirectUrl: redirectUrl, tokens: tokens })
          Gmail.findMessagesList({limit: 5, labels: {id: 'CATEGORY_SOCIAL'}}, (status, response) ->
            Gmail.findMessagesGet(response, (status, response) ->
              async.eachSeries(response, (val, next) ->
                 expect(val).to.have.property('title')
                 expect(val).to.have.property('date')
                 expect(val).to.have.property('snippet')
                 next()
              , (result) -> #async.eachSeries done
                done()
              )
            )
          )

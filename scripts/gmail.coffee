# Description:
#   hubot Google Gmail Apis commands
#
# Commands:
#   hubot google gmail get new <n>  - I get a lastest GMail title and body (n)
#

CronJob = require("cron").CronJob
#inbox = require("inbox")

#job = new CronJob(
#  cronTime: "*/5 * * * * *"
#  onTick: ->
#    gmailNotify()
#    return
#  start: true
#)
#
#gmailNotify = ->
#  console.log "This is task A"


module.exports = (robot) ->

  google = require('googleapis')
  gmail  = google.gmail 'v1'
  OAuth2 = google.auth.OAuth2
  async  = require('async')
  base64url = require('base64url')

  brainKeys = require('./../configs/brain_key.json')

  #
  # Google Oauth Client
  # @return {OAuth2}
  #
  getOAuthClient = () ->
    OAuthClient = new OAuth2(
      process.env.HUBOT_GOOGLE_CLIENT_ID,
      process.env.HUBOT_GOOGLE_CLIENT_SECRET,
      process.env.HUBOT_GOOGLE_REDIRECT_URL)
    tokens = getOauthTokens()
    OAuthClient.setCredentials(
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token
    )
    return OAuthClient


  #
  # getter tokens
  # @return {object} token response
  #
  getOauthTokens = () ->
    return robot.brain.get(brainKeys.tokens)

  #
  # setter tokens
  # @param {object} token response
  #
  setOauthTokens = (tokens) ->
    return robot.brain.set(brainKeys.tokens, tokens)

  robot.respond /google\s*(.gmail\sget\snew)\s?(.*)?$/i, (msg) ->
    limit = 5
    limit = msg.match[2] if msg.match[2]?
    OAuthClient = getOAuthClient()

    async.waterfall([
      # get users message list
      (callback) ->
        data =
          response    : {}
          oAuthClient : OAuthClient

        gmail.users.messages.list {userId: 'me', auth: OAuthClient}, (err, response) ->
          # token Expire over
          if err? && err.code == 401
            OAuthClient.refreshAccessToken (err, tokens) ->
              if err?
                callback('failed. Google OAuth get refresh token', err)
                return false

              setOauthTokens(tokens)
              OAuthClient.setCredentials( access_token : tokens.access_token, refresh_token: tokens.refresh_token )
              data.oAuthClient = OAuthClient

              gmail.users.messages.list {userId: 'me', auth: OAuthClient}, (err, response) ->
                if err?
                  callback('failed. Gmail API Users.messages.list', err)
                  return false

                data.response = response
                callback(null, data)

          data.response = response
          callback(null, data)
      (data, callback) ->
        data =
          response    : 
            messagesList : data.response
          oAuthClient : OAuthClient

        data.response.messagesList = data.response.messagesList.messages.slice(0,limit)
        num = 0
        async.eachSeries data.response.messagesList, (val, next) ->
          #console.log val
          gmail.users.messages.get {
            userId : 'me',
            auth   : data.oAuthClient,
            id     : val.id
          }, (err, response) ->
            # token Expire over
            if err? && err.code == 401
              OAuthClient.refreshAccessToken (err, tokens) ->
                if err?
                  callback('failed. Google OAuth get refresh token', err)
                  return false

                setOauthTokens(tokens)
                OAuthClient.setCredentials( access_token : tokens.access_token, refresh_token: tokens.refresh_token )
                data.oAuthClient = OAuthClient
                gmail.users.messages.get {
                  userId : 'me',
                  auth   : data.oAuthClient,
                  id     : val.id
                }, (err, response) ->
                  if err?
                    callback('failed. Gmail API Users.messages.get', err)
                    return false

            data.response.messagesList[num].title = ''
            data.response.messagesList[num].body = ''
            async.eachSeries response.payload.headers, (val, next) ->
              return next() if val.name != 'Subject'
              data.response.messagesList[num].title = val.value

            body = base64url.decode(response.payload.body.data)
            data.response.messagesList[num].body = body

            num++
            next()

        , (err) -> #async.eachSeries done
          callback(null, data.response.messagesList)
    (data, callback) -> # data toString
      replyText = []
      async.eachSeries data, (val, next) ->
        replyText.push(val.title.replace(/[\n\r]/g,"\n"))
        replyText.push(val.body.replace(/[\n\r]/g,"\n"))
        next()
      , (err) -> #async eachSeries done
        callback(null, replyText.join(''))

    ], (err, result) ->
      throw new Error('#{err}') if err
      msg.reply "
Latest mail list.\n
#{result}
      "
    )


# Description:
#   hubot Google Gmail Apis commands
#
# Commands:
#   hubot google gmail get messages list <n>  - I get a lastest GMail title
#

'use strict'

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

  robot.respond /google\s*(.gmail\sget\smessages\slist)\s?(.*)?$/i, (msg) ->
    limit = 5
    limit = msg.match[2] if msg.match[2]?
    OAuthClient = getOAuthClient()

    async.waterfall([
      # get users message list(Id list)
      (callback) ->
        data =
          tokenExpireOver : false
          response        : {}

        gmail.users.messages.list {userId: 'me', auth: OAuthClient}, (err, response) ->
          unless err?
            # optional limit slice
            data.response.messages = response.messages.slice(0, limit)
            return callback(null, data)

          # token Expire over
          if err.code == 401
            data.tokenExpireOver = true
            return callback(null, data)

          return callback("failed. [Google Gmail Api] gmail.users.messages.list code: #{err.code}", err) if err?

      # token Expire Over. retry gmail.messages.list
      (data, callback) ->
        return callback(null, data) if data.tokenExpireOver == false

        console.log 'token Expire retry'
        OAuthClient.refreshAccessToken (err, tokens) ->
          return callback('failed. Google OAuth get refresh token', err) if err?

          setOauthTokens(tokens)
          OAuthClient.setCredentials( access_token : tokens.access_token, refresh_token: tokens.refresh_token )

          gmail.users.messages.list {userId: 'me', auth: OAuthClient}, (err, response) ->
            callback('failed. Gmail API Users.messages.list', err) if err?
            # optional limit slice
            data.response.messages  = response.messages.slice(0, limit)
            return callback(null, data)
      # get a message detail
      (data, callback) ->
        data.tokenExpireOver = false
        data.messages = { num : 0 }
        async.eachSeries data.response.messages, (val, next) ->
          gmail.users.messages.get {
            userId : 'me',
            auth   : OAuthClient,
            id     : val.id
          }, (err, response) ->
            unless err?
              data.response.messages[data.messages.num].title = ''
              data.response.messages[data.messages.num].body = ''
              async.eachSeries response.payload.headers, (val, next) ->
                return next() if val.name != 'Subject'
                data.response.messages[data.messages.num].title = val.value

              data.response.messages[data.messages.num].body = base64url.decode(response.payload.body.data)

              data.messages.num++
              return next()

            # token Expire over
            if err.code == 401
              data.tokenExpireOver = true
              data.next            = next
              console.log 'token expire here'
              return callback(null, data)

        , (err) -> #async.eachSeries done
          data.tokenExpireOver = false
          delete data.next if data.next?
          delete data.messages if data.messages?
          return callback(null, data)
    # token Expire Over. retry gmail.messages.get <id>
    (data, callback) ->
      # before callback each series end point.
      return callback(null, data.response.messages) if data.tokenExpireOver == false
      console.log data
      OAuthClient.refreshAccessToken (err, tokens) ->
        return callback('failed. Google OAuth get refresh token', err) if err?

        setOauthTokens(tokens)
        OAuthClient.setCredentials( access_token : tokens.access_token, refresh_token: tokens.refresh_token )
        gmail.users.messages.get {
          userId : 'me',
          auth   : OAuthClient,
          id     : data.response.messages[data.messages.num].id
        }, (err, response) ->
          return callback('failed. Gmail API Users.messages.get', err) if err?
          console.log 'retry messages get'

          data.response.messages[data.messages.num].title = ''
          data.response.messages[data.messages.num].body = ''
          async.eachSeries response.payload.headers, (val, next) ->
            return next() if val.name != 'Subject'
            data.response.messages[data.messages.num].title = val.value

          data.response.messages[data.messages.num].body = base64url.decode(response.payload.body.data)

          data.messages.num++
          return data.next()
    #data toString
    (messages, callback) ->
      replyText = []
      async.eachSeries messages, (val, next) ->
        replyText.push(val.title.replace(/[\n\r]/g,"\n"))
        #replyText.push(val.body.replace(/[\n\r]/g,"\n"))
        next()
      , (err) -> #async eachSeries done
        callback(null, replyText.join("\n"))

    ], (err, result) ->
      throw new Error('#{err}') if err
      msg.reply result
    )


# Description:
#   hubot Google Gmail Apis commands
#
# Commands:
#   hubot google gmail get messages list <n>  - I get a lastest GMail title list
#   hubot google gmail get messages list by labelName <label name>  - get a lastest GMail list by label name.
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
  # Array chunk
  #
  Array::chunk = (chunkSize) ->
    array = this
    [].concat.apply [], array.map (elem, i) ->
      (if i % chunkSize then [] else [array.slice(i, i + chunkSize)])

  args2HashTable = (args) ->
    params = {}
    args.split(' ').map (elem, i) ->
      array = elem.split(':')
      return unless array.length == 2
      array[1] = parseInt(array[1]) unless isNaN(array[1])
      params[array[0]] = array[1]

    return params

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

  #
  # merge messages.get and messages.list
  # @param {Object} response Google Apis Gmail::Users.messages:get response
  # @param {Object} messages data object
  # @param {Number} terget messages.list key
  # @return {Object} merge data
  #
  mergeResponseMessages = (response, messages, num) ->
    messages[num].title = ''
    messages[num].body = ''

    async.eachSeries response.payload.headers, (val, next) ->
      return next() if val.name != 'Subject'
      messages[num].title = val.value

    messages[num].body = base64url.decode(response.payload.body.data) if response.payload.body.size > 0
    return messages

  #
  # get gmail list message 
  #
  getMessagesList = (options, msg) ->
    OAuthClient = getOAuthClient()

    params =
      userId     : 'me',
      auth       : OAuthClient
      maxResults : options.limit

    params.labelIds = options.label.id if options.label?

    async.waterfall([
      # get messages.list
      (callback) ->
        data = messages : {}
        gmail.users.messages.list params, (err, response) ->
          unless err?
            data.messages = response.messages
            return callback(null, data) unless err?

          # token Expire over
          if err.code == 401
            OAuthClient.refreshAccessToken (err, tokens) ->
              return callback( failedRefreshAccessToken : true, err) if err?

              setOauthTokens(tokens)
              OAuthClient.setCredentials( access_token : tokens.access_token, refresh_token: tokens.refresh_token )

              gmail.users.messages.list params, (err, response) ->
                return callback( { isApiError : true, apiName : 'gmail.users.messages.list'}, err) if err?
                data.messages = response.messages
                return callback(null, data)
      # loop collector messages row
      (data, callback) ->
        data.num = 0
        async.eachSeries data.messages, (val, next) ->
          data.callback = next
          data.message  = val
          return callback(null, data)
        , (err) -> #async.eachSeries done
          console.log 'done'
          return callback(null, data.messages)

      #each messages get mail details
      (data, callback) ->
        return callback(null, data) unless data.callback?
        gmail.users.messages.get { userId : params.userId, auth : params.auth, id : data.messages[data.num].id }, (err, response) ->
          unless err?
            data.messages = mergeResponseMessages(response, data.messages, data.num)
            data.num++
            return data.callback()

          # token Expire over
          if err.code == 401
            OAuthClient.refreshAccessToken (err, tokens) ->
              return callback( failedRefreshAccessToken : true, err) if err?

              setOauthTokens(tokens)
              OAuthClient.setCredentials( access_token : tokens.access_token, refresh_token: tokens.refresh_token )

              gmail.users.messages.get { userId : params.userId, auth : params.auth, id : data.messages[data.num].id }, (err, response) ->
                return callback( { isApiError : true, apiName : 'gmail.users.messages.get'}, err) if err?

                data.messages = mergeResponseMessages(response, data.messages, data.num)
                data.num++
                return data.callback()

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
      if err?
        return msg.reply "OAuth token refresh failed. [code : #{result.code} message : #{result.message}]" if err.failedRefreshAccessToken?
        return msg.reply "Api #{err.apiName} failed. [code : #{result.code} message : #{result.message}}]" if err.isApiError?
      return msg.reply result
    )
  #
  # respond Gmail lastetst list by label name
  #
  robot.respond /google\s*(.gmail\sget\smessages\slist)\s(.*)?$/i, (msg) ->
    return false unless msg.match[2]
    options = args2HashTable(msg.match[2])
    options.limit = 5 unless options.limit?

    OAuthClient = getOAuthClient()

    async.waterfall([
      # get users labels list(Id list)
      (callback) ->
        return callback({ notExistsLabelName : true}, data) unless options.labelName?

        data = labels : {}
        gmail.users.labels.list {userId: 'me', auth: OAuthClient}, (err, response) ->
          unless err?
            data.labels = response.labels
            return callback(null, data) unless err?

          # token Expire over
          if err.code == 401
            OAuthClient.refreshAccessToken (err, tokens) ->
              return callback('failed. Google OAuth get refresh token', err) if err?

              setOauthTokens(tokens)
              OAuthClient.setCredentials( access_token : tokens.access_token, refresh_token: tokens.refresh_token )

              gmail.users.labels.list {userId: 'me', auth: OAuthClient}, (err, response) ->
                return callback('failed. Gmail API Users.labels.list', err) if err?
                data.labels = response.labels
                return callback(null, data)

      # filter lables
      (data, callback) ->
        async.eachSeries data.labels, (val, next) ->
          return next() unless val.name == options.labelName
          data.label = val
          return next()
        , (err) -> #async.eachSeries done
          return callback({ hasNotLabelName: true }, data) unless data.label?
          return callback(null, data.label)

    ], (err, result) ->
      if err?
        return msg.reply "has not labelName. [labelName : #{options.labelName}]" if err.hasNotLabelName?
        return getMessagesList({limit : options.limit}, msg)                     if err.notExistsLabelName?

      getMessagesList({ label : result, limit : options.limit}, msg)
    )


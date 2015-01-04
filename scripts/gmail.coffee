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
  response = []

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


  replyParse = (messages, callback) ->
    replyText = []
    async.eachSeries messages, (val, next) ->
      replyText.push(val.title.replace(/[\n\r]/g,"\n"))
      #replyText.push(val.body.replace(/[\n\r]/g,"\n"))
      next()
    , (err) -> #async eachSeries done
      return callback(null, replyText.join("\n"))

  getLabelsList = (options, msg) ->
    OAuthClient = getOAuthClient()

    params =
      userId     : 'me'
      auth       : OAuthClient

    async.waterfall([
      # get users labels list(Id list)
      (callback) ->
        return callback({ notExistsLabelName : true}, null) unless options.labelName?

        gmail.users.labels.list params, (err, response) ->
          return callback(null, response.labels) unless err?

          # token Expire over
          if err.code == 401
            OAuthClient.refreshAccessToken (err, tokens) ->
              return callback('failed. Google OAuth get refresh token', err) if err?

              setOauthTokens(tokens)
              OAuthClient.setCredentials( access_token : tokens.access_token, refresh_token: tokens.refresh_token )

              gmail.users.labels.list params, (err, response) ->
                return callback( { isApiError : true, apiName : 'gmail.users.labels.list'}, err) if err?
                return callback(null, response.labels)
      # filter lables
      (labels, callback) ->
        async.eachSeries labels, (val, next) ->
          return next(val) if val.name == options.labelName
          return next()
        , (result) -> #async.eachSeries done
          return callback({ hasNotLabelName: true }, data) unless result?
          return callback(null, result)
    ], (status, result) ->
      if err?
        return options.callback(null, null)                                                    if status.notExistsLabelName?
        return options.callback("has not labelName. [labelName : #{options.labelName}]", null) if status.hasNotLabelName?
        return options.callback(status, result)
      return options.callback(null, result)
    )

  #
  # get gmail list message 
  #
  getMessagesList = (options) ->
    OAuthClient = getOAuthClient()

    params =
      userId     : 'me',
      auth       : OAuthClient
      maxResults : options.limit
    params.labelIds = options.labels.id if options.labels?

    async.waterfall([
      # get messages.list
      (callback) ->
        gmail.users.messages.list params, (err, response) ->
          return callback(null, response.messages) unless err?

          # token Expire over
          if err.code == 401
            OAuthClient.refreshAccessToken (err, tokens) ->
              return callback( failedRefreshAccessToken : true, err) if err?

              setOauthTokens(tokens)
              OAuthClient.setCredentials( access_token : tokens.access_token, refresh_token: tokens.refresh_token )

              gmail.users.messages.list params, (err, response) ->
                return callback( { isApiError : true, apiName : 'gmail.users.messages.list'}, err) if err?
                return callback(null, response.messages)

    ], (status, result) ->
      return options.callback(status, result) if status?
      return options.callback(null, result)
    )

  getMessages = (options) ->
    OAuthClient = getOAuthClient()

    params =
      userId     : 'me'
      auth       : OAuthClient

    response = []
    async.waterfall([
      # get messages.get
      (callback) ->
        async.eachSeries options.messageIds, (val, next) ->
          params.id = val.id
          return callback(null, { apiParams : params, eachCallback : next  })
        , (result) -> #async.eachSeries donea
          return callback( { isDone : true }, response )
      (data, callback) ->
        gmail.users.messages.get data.apiParams, (err, response) ->
          return callback(null, { response : response, eachCallback : data.eachCallback }) unless err?

          # token Expire over
          if err.code == 401
            OAuthClient.refreshAccessToken (err, tokens) ->
              return callback( failedRefreshAccessToken : true, err) if err?

              setOauthTokens(tokens)
              OAuthClient.setCredentials( access_token : tokens.access_token, refresh_token: tokens.refresh_token )

              gmail.users.messages.get data.apiParams, (err, response) ->
                return callback( { isApiError : true, apiName : 'gmail.users.messages.get'}, err) if err?
                return callback(null, { response : response, eachCallback : data.eachCallback }) unless err?

      # get message find header
      (data, callback) ->
        body = base64url.decode(data.response.payload.body.data) if data.response.payload.body.size > 0
        title = ''
        async.eachSeries data.response.payload.headers, (val, next) ->
          if val.name == 'Subject'
            title = val.value
          next()
        , (result) -> #async.eachSeries done
          response.push({title: title, body : body})
          return data.eachCallback()

    ], (status, result) ->
      return options.callback(status, result) if status? && status.isDone? == false
      return options.callback(null, response)
    )

  #
  # respond Gmail lastetst list by label name
  #
  robot.respond /google\s*(.gmail\sget\smessages\slist)\s?(.*)$/i, (msg) ->
    options = args2HashTable(msg.match[2])
    options.limit = 5 unless options.limit?

    OAuthClient = getOAuthClient()

    async.waterfall([
      # get users labels list(Id list)
      (callback) ->
        options.callback = callback
        getLabelsList(options, msg)
      (labels, callback) ->
        options.callback = callback
        options.labels   = labels   if labels?
        getMessagesList(options)
      (messagesList, callback) ->
        getMessages({ messageIds : messagesList, callback : callback })
      (messages, callback) ->
        replyParse messages, callback
    ], (err, result) ->
      if err?
        return msg.reply "OAuth token refresh failed. [code : #{result.code} message : #{result.message}]" if err.failedRefreshAccessToken?
        return msg.reply "Api #{err.apiName} failed. [code : #{result.code} message : #{result.message}}]" if err.isApiError?
      return msg.reply result
    )


# Description:
#   hubot Google Gmail Apis commands
#
# Commands:
#   hubot google gmail get messages list <n>  - I get a lastest GMail title list
#   hubot google gmail get messages list labelName:hoge  - get a lastest GMail list by label name.
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

  #
  # args to HashTable 
  # ex hoge:fuga >> {hoge:fuga}
  # @param {String} args hoge:fuga
  # @return {object} convert to hash
  #
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
  # hubot reply to message parse ned of line and mail info 
  # @param {Array} gmail info
  # @param {object} callable Object
  # @return {object} callback response
  #
  replyParse = (messages, callback) ->
    replyText = []
    async.eachSeries messages, (val, next) ->
      replyText.push(val.title.replace(/[\n\r]/g,"\n"))
      #replyText.push(val.body.replace(/[\n\r]/g,"\n"))
      next()
    , (err) -> #async eachSeries done
      return callback(null, replyText.join("\n"))

  #
  # gmail API Users.labels: list fetch and validate
  # @param {String} labelName args labelName
  # @param {object} parentCallback main process callback async waterfall
  # @return {object} parent callback response
  #
  getLabelsList = (labelName, parentCallback) ->
    OAuthClient = getOAuthClient()

    params =
      userId     : 'me'
      auth       : OAuthClient

    async.waterfall([
      # get users labels list(Id list)
      (callback) ->
        return callback({ notExistsLabelName : true}, null) unless labelName?

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
          return next(val) if val.name == labelName
          return next()
        , (result) -> #async.eachSeries done
          return callback({ hasNotLabelName: true }, data) unless result?
          return callback(null, result)
    ], (status, result) ->
      if err?
        return parentCallback(null, null)                                            if status.notExistsLabelName?
        return parentCallback("has not labelName. [labelName : #{labelName}]", null) if status.hasNotLabelName?
        return parentCallback(status, result)
      return parentCallback(null, result)
    )

  #
  # gmail API Users.messages: list fetch and validate
  # @param {object} apiParams api options params
  # @param {object} parentCallback main process callback async waterfall
  # @return {object} parent callback response
  #
  getMessagesList = (apiParams, parentCallback) ->
    OAuthClient = getOAuthClient()

    params =
      userId     : 'me',
      auth       : OAuthClient
      maxResults : apiParams.limit
    params.labelIds = apiParams.labels.id if apiParams.labels?

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
      return parentCallback(status, result) if status?
      return parentCallback(null, result)
    )

  #
  # gmail API Users.messages: get fetch and validate
  # @param {Array} messageIds api option params messageIds
  # @param {object} parentCallback main process callback async waterfall
  # @return {object} parent callback response
  #
  getMessages = (messageIds, parentCallback) ->
    OAuthClient = getOAuthClient()

    params =
      userId     : 'me'
      auth       : OAuthClient

    asyncResult = []
    async.waterfall([
      # get messages.get
      (callback) ->
        async.eachSeries messageIds, (val, next) ->
          params.id = val.id
          return callback(null, { apiParams : params, eachCallback : next  })
        , (result) -> #async.eachSeries done
          return callback( { isDone : true }, asyncResult )
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
                return callback(null, { response : response, eachCallback : data.eachCallback })

      # get message find header
      (data, callback) ->
        body = base64url.decode(data.response.payload.body.data) if data.response.payload.body.size > 0
        title = ''
        async.eachSeries data.response.payload.headers, (val, next) ->
          title = val.value if val.name == 'Subject'
          next()
        , (err) -> #async.eachSeries done
          asyncResult.push({title: title, body : body})
          # back to first callback eachSeries
          return data.eachCallback()

    ], (status, result) ->
      return parentCallback(status, result) if status? && status.isDone? == false
      return parentCallback(null, asyncResult)
    )

  #
  # respond Gmail lastetst list by label name
  #
  robot.respond /google\s*(.gmail\sget\smessages\slist)\s?(.*)$/i, (msg) ->
    options = args2HashTable(msg.match[2])
    options.limit = 5 unless options.limit?

    async.waterfall([
      # get users labels list(Id list)
      (callback) ->
        getLabelsList(options.labelName, callback)
      (labels, callback) ->
        options.labels = labels if labels?
        getMessagesList(options, callback)
      (messagesList, callback) ->
        getMessages(messagesList, callback)
      (messages, callback) ->
        replyParse messages, callback
    ], (err, result) ->
      if err?
        return msg.reply "OAuth token refresh failed. [code : #{result.code} message : #{result.message}]" if err.failedRefreshAccessToken?
        return msg.reply "Api #{err.apiName} failed. [code : #{result.code} message : #{result.message}}]" if err.isApiError?
      return msg.reply result
    )


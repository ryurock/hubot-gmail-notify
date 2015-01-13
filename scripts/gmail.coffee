# Description:
#   hubot Google Gmail Apis commands
#
# Commands:
#   hubot google gmail get messages list <n>  - I get a lastest GMail title list
#   hubot google gmail get messages list labelName:hoge  - get a lastest GMail list by label name.
#

'use strict'

module.exports = (robot) ->
  gmailClient = require('./../src/gmail')

  async     = require('async')
  base64url = require('base64url')
  cron      = require("cron").CronJob
  moment    = require('moment')

  brainKeys = require('./../configs/brain_key.json')

  #job = new cron(
  #  cronTime: "*/5 * * * * *"
  #  onTick: ->
  #    options = labels : 'ecnavi_error', limit : 5
  #    async.waterfall([
  #      # get users labels list(Id list)
  #      (callback) ->
  #        getLabelsList(options.labels, callback)
  #      (labels, callback) ->
  #        options.labels = labels if labels?
  #        getMessagesList(options, callback)
  #      (messagesList, callback) ->
  #        getMessages(messagesList, callback)
  #      (messages, callback) ->
  #        replyParse options.labels.name, messages, callback
  #    ], (err, result) ->
  #      if err?
  #        return robot.send {room: "#test-kimura"}, "OAuth token refresh failed. [code : #{result.code} message : #{result.message}]" if err.failedRefreshAccessToken?
  #        return robot.send {room: "#test-kimura"}, "Api #{err.apiName} failed. [code : #{result.code} message : #{result.message}}]" if err.isApiError?

  #      return robot.send {room: "#test-kimura"}, result)
  #    return
  #  start: true
  #)



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
  replyParse = (labelName, messages, callback) ->
    if labelName?
      replyText = ["ラベル:" + labelName + "での検索結果だぬーーーーーーん"]
    else
      replyText = ["検索結果だぬーーーーん"]

    async.eachSeries messages, (val, next) ->
      replyText.push(val.date + " " + val.title.replace(/[\n\r]/g,"\n"))
      replyText.push(val.snippet.replace(/[\n\r]/g,"\n") + "......")
      replyText.push("=============================================================================")
      #replyText.push(val.body.replace(/[\n\r]/g,"\n"))
      next()
    , (err) -> #async eachSeries done
      return callback(null, replyText.join("\n"))

  #
  # respond Gmail lastetst list by label name
  #
  robot.respond /google\s*(.gmail\sget\smessages\slist)\s?(.*)$/i, (msg) ->
    options = args2HashTable(msg.match[2])
    options.limit = 5 unless options.limit?
    tokens = getOauthTokens()
    gmailClient.configure({
      clientId: process.env.HUBOT_GOOGLE_CLIENT_ID, 
      clientSecret: process.env.HUBOT_GOOGLE_CLIENT_SECRET, 
      redirectUrl: process.env.HUBOT_GOOGLE_REDIRECT_URL,
      tokens: {
        accessToken:  tokens.access_token,
        refreshToken: tokens.refresh_token
      }
    })

    async.waterfall([
      # get users labels list(Id list)
      (callback) ->
        return callback(null, null) unless options.labelName?
        return gmailClient.findLabelsList(options.labelName, callback)
      (labels, callback) ->
        apiParams = { limit: options.limit  }
        apiParams.labels = { id: labels.id } if labels?
        return gmailClient.findMessagesList(apiParams, callback)
      (messagesList, callback) ->
        return gmailClient.findMessagesGet(messagesList, callback)
      (messages, callback) ->
        replyParse options.labelName, messages, callback
    ], (err, result) ->
      if err?
        return msg.reply "OAuth token refresh failed. [code : #{result.code} message : #{result.message}]" if err.failedRefreshAccessToken?
        return msg.reply "Api #{err.apiName} failed. [code : #{result.code} message : #{result.message}}]" if err.isApiError?
      return msg.reply result
    )


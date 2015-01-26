# Description:
#   hubot Google Gmail Apis commands
#
# Commands:
#   hubot google gmail get messages list limit:<n> list labelName:hoge - get a lastest Gmail list. <labelName> optional labels. <limit> optional limit. default is 5
#

'use strict'

module.exports = (robot) ->
  gmailClient = require('./../src/gmail')
  argsUtils   = require('./../src/cli/args')

  async     = require('async')
  base64url = require('base64url')
  cron      = require("cron").CronJob
  moment    = require('moment')

  brainKeys = require('./../configs/brain_key.json')

  #
  # Array chunk
  #
  Array::chunk = (chunkSize) ->
    array = this
    [].concat.apply [], array.map (elem, i) ->
      (if i % chunkSize then [] else [array.slice(i, i + chunkSize)])

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
    replyText = ["検索結果だぬーーーーん"]
    replyText = ["ラベル:" + labelName + "での検索結果だぬーーーーーーん"] if labelName?

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
    options = argsUtils.args2HashTable(msg.match[2])
    options.limit = 5 unless options.limit?
    tokens = getOauthTokens()
    gmailClient.configure({
      clientId:     process.env.HUBOT_GOOGLE_CLIENT_ID, 
      clientSecret: process.env.HUBOT_GOOGLE_CLIENT_SECRET, 
      redirectUrl:  process.env.HUBOT_GOOGLE_REDIRECT_URL,
      tokens:       { accessToken:  tokens.access_token, refreshToken: tokens.refresh_token }
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


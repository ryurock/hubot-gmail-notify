# Description:
#   You can use the Gmail API https://developers.google.com/gmail/api/ to notify you when new mail trees
#
# Commands:
#   hubot google gmail add notify labelName:hoge - add Notify the gmail by specifying the label
#   hubot google gmail set notify labelName:hoge - set Notify the gmail by specifying the label
#   hubot google gmail get notify labelsName - get all of Gmail label that has been registered for notification
#   hubot google gmail search notify labelName:hoge - find the Gmail label that has been registered for notification
#

'use strict'

module.exports = (robot) ->

  gmailClient = require('./../src/gmail')
  argsUtils   = require('./../src/cli/args')
  async       = require('async')
  cron        = require("cron").CronJob

  brainKeys = require('./../configs/brain_key.json')

  #
  # getter tokens
  # @return {object} token response
  #
  getOauthTokens = () ->
    return robot.brain.get(brainKeys.tokens)
  #
  # getter tokens
  # @return {object} token response
  #
  getNotifyLabels = () ->
    return robot.brain.get(brainKeys.notify_by_label)

  #
  # add hubot brain add notify
  # @param {object} label GMail label data
  #
  addNotifyLabels = (label) ->
    storage = robot.brain.get(brainKeys.notify_by_label)
    storage = [] unless storage?
    storage.push(label)
    return robot.brain.set(brainKeys.notify_by_label, storage)

  #
  # set hubot brain add notify
  # @param {object} label GMail label data
  #
  setNotifyLabels = (label) ->
    storage = []
    storage.push(label)
    return robot.brain.set(brainKeys.notify_by_label, storage)

  #
  # respond Gmail notify set by labelName
  #
  robot.respond /google\s*(.gmail\sadd\snotify)\s?(.labelName:.*)$/i, (msg) ->
    labelName = argsUtils.args2HashTable(msg.match[2]).labelName
    return msg.reply "not found labelName" unless labelName?
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
        return gmailClient.findLabelsList(labelName, callback)
      (labels, callback) ->
        storage = getNotifyLabels()
        unless storage?
          addNotifyLabels(labels)
          return callback( null, "add notify labelName[#{labelName}]")

        async.eachSeries storage, (val, next) ->
          return next(true) if val.id == labels.id
          next()
        , (result) -> #async.eachSeries done
            return callback(null, "already set notify labelName[#{labelName}]") if result?
            addNotifyLabels(labels)
            return callback( null, "add notify labelName[#{labelName}]")
    ], (err, result) ->
      if err?
        return msg.reply "OAuth token refresh failed. [code : #{result.code} message : #{result.message}]" if err.failedRefreshAccessToken?
        return msg.reply "Api #{err.apiName} failed. [code : #{result.code} message : #{result.message}}]" if err.isApiError?
        return msg.reply err.message                                                                       if err.hasNotLabelName?

      return msg.reply result
    )

  #
  # respond Gmail notify set by labelName
  #
  robot.respond /google\s*(.gmail\sset\snotify)\s?(.labelName:.*)$/i, (msg) ->
    labelName = argsUtils.args2HashTable(msg.match[2]).labelName
    return msg.reply "not found labelName" unless labelName?
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
        return gmailClient.findLabelsList(labelName, callback)
      (labels, callback) ->
        setNotifyLabels(labels)
        return callback( null, "set notify labelName[#{labelName}]")
    ], (err, result) ->
      if err?
        return msg.reply "OAuth token refresh failed. [code : #{result.code} message : #{result.message}]" if err.failedRefreshAccessToken?
        return msg.reply "Api #{err.apiName} failed. [code : #{result.code} message : #{result.message}}]" if err.isApiError?
        return msg.reply err.message                                                                       if err.hasNotLabelName?

      return msg.reply result
    )

  #
  # respond Gmail notify search by labelName
  #
  robot.respond /google\s*(.gmail\ssearch\snotify)\s?(.labelName:.*)$/i, (msg) ->
    labelName = argsUtils.args2HashTable(msg.match[2]).labelName
    return msg.reply "not found labelName" unless labelName?
    storage = getNotifyLabels()

    async.eachSeries storage, (val, next) ->
      next(true) if val.name == labelName
      next()
    , (result) -> #async.eachSeries done
      return msg.reply "label [#{labelName}] is already notify terget." if result?
      return msg.reply "label [#{labelName}] is not notify terget."

  #
  # respond Gmail notify find all LanelsName
  #
  robot.respond /google\s*(.gmail\sget\snotify\slabelsName)$/i, (msg) ->
    storage = getNotifyLabels()
    return msg.reply "no registed labelsName" unless storage?
    return msg.reply "no registed labelsName" if storage.length <= 0

    replyText = ["registed notify labelsName. all"]
    replyText.push("====================================")
    async.eachSeries storage, (val, next) ->
      replyText.push("- #{val.name}")
      next()
    , (result) -> #async.eachSeries done
      replyText.push("====================================")
      return msg.reply replyText.join("\n")

  #
  # respond Gmail notify search by labelName
  #
  robot.respond /google\s*(.gmail\sdel\snotify)\s?(.labelName:.*)$/i, (msg) ->
    labelName = argsUtils.args2HashTable(msg.match[2]).labelName
    return msg.reply "not found labelName" unless labelName?
    storage = getNotifyLabels()

    i = 0
    async.eachSeries storage, (val, next) ->
      if val.name == labelName
        storage.splice(i, 1)
        robot.brain.set(brainKeys.notify_by_label, storage)
        return next(true)

      i++
      next()
    , (result) -> #async.eachSeries done
      return msg.reply "label [#{labelName}] is notify not found." unless result?
      return msg.reply "label [#{labelName}] is notify delete."


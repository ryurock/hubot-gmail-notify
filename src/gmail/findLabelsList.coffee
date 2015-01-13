'use strict'

#
# find Labels list to labelsName
# @param {String} labelsName label name
# @param {Function} parentCallback callback function
# @return {Function} parentCallback
#
module.exports = (labelsName, parentCallback) ->
  throw new Error('args labelsName not found') unless labelsName?

  OAuthClient = @oAuthClient()
  google      = require('googleapis')
  gmail       = google.gmail 'v1'
  async       = require('async')

  params = { userId: 'me',auth: OAuthClient }

  async.waterfall([
    # get users labels list(Id list)
    (callback) ->
      gmail.users.labels.list params, (err, response) ->
        return callback(null, response.labels) unless err?
        apiErrorHandler(err,callback)
    # filter lables
    (labels, callback) ->
      async.eachSeries labels, (val, next) ->
        return next(val) if val.name == labelsName
        return next()
      , (result) -> #async.eachSeries done
        return callback({ hasNotLabelName: true, message: "has not labelName. [labelName : #{labelsName}]" }, null) unless result?
        return callback(null, result)
  ], (status, result) ->
    return parentCallback(null, result)   unless status?
    return parentCallback(status, result) if status.unknownError?
    return parentCallback(status, null)   if status.hasNotLabelName?
    return parentCallback(status, result)
  )

  #
  # api error handler
  #
  apiErrorHandler = (err, callback) ->
    # token Expire over
    if err.code == 401
      OAuthClient.refreshAccessToken (err, tokens) ->
        return callback( {unknownError: true, message:"#{err}" } ) if err?

        OAuthClient.setCredentials( access_token : tokens.access_token, refresh_token: tokens.refresh_token )

        gmail.users.labels.list params, (err, response) ->
          return callback( { isApiError : true }, err) if err?
          return callback(null, response.labels)
    else
      return callback( { unknownError: true }, err)

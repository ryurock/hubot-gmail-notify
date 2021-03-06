'use strict'

#
# find Messages list
# @param {Object} apiParams API Users.messages: list api Params
# @param {Function} parentCallback callback function
# @return {Function} parentCallback
#
module.exports = (apiParams, parentCallback) ->
  throw new Error('args apiParams not found')              unless apiParams?
  throw new Error('args apiParams is not Object')          unless typeof apiParams is "object"

  OAuthClient = @oAuthClient()
  google      = require('googleapis')
  gmail       = google.gmail 'v1'
  async       = require('async')

  params = { userId: 'me',auth: OAuthClient, maxResults: apiParams.limit}
  params.labelIds = apiParams.labels.id if apiParams.labels?

  async.waterfall([
    # get messages.list
    (callback) ->
      gmail.users.messages.list params, (err, response) ->
        return callback(null, response.messages) unless err?
        apiErrorHandler(err,callback)
  ], (status, result) ->
    return parentCallback(null, result)   unless status?
    return parentCallback(status, result) if status.unknownError?
    return parentCallback(status, null)   if status.hasNotLabelName?
    return parentCallback(status, result)
  )

  #
  # api error handler
  # @param {object} err API error response
  # @param {Fundtion} callback
  # @return {Function} args callback callback
  #
  apiErrorHandler = (err, callback) ->
    # token Expire over
    if err.code == 401
      OAuthClient.refreshAccessToken (err, tokens) ->
        return callback( {unknownError: true, message:"#{err}" } ) if err?

        OAuthClient.setCredentials( access_token : tokens.access_token, refresh_token: tokens.refresh_token )

        gmail.users.messages.list params, (err, response) ->
          return callback( { isApiError : true }, err) if err?
          return callback(null, response.messages)
    else
      return callback( { unknownError: true }, err)

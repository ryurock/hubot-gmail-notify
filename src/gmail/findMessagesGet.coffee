'use strict'

#
# find Messages list
# @param {Object} apiParams API Users.messages: list api Params
# @param {Function} parentCallback callback function
# @return {Function} parentCallback
#
module.exports = (messagesIds, parentCallback) ->
  throw new Error('args messagesIds not found')   unless messagesIds?
  throw new Error('args apiParams is not Object') unless typeof messagesIds is "object"

  OAuthClient = @oAuthClient()
  google      = require('googleapis')
  gmail       = google.gmail 'v1'
  async       = require('async')
  moment      = require('moment')
  base64url   = require('base64url')

  asyncResult = []
  async.waterfall([
    # get messages.get
    (callback) ->
      async.eachSeries messagesIds, (val, next) ->
        params = { userId: 'me',auth: OAuthClient, id: val.id }
        return callback(null, { apiParams : params, eachCallback : next  })
      , (result) -> #async.eachSeries done
        return callback( { isDone : true }, asyncResult )
    (data, callback) ->
      gmail.users.messages.get data.apiParams, (err, response) ->
        return callback(null, { response : response, eachCallback : data.eachCallback }) unless err?
        apiErrorHandler(err, data, callback)

    # get message find header
    (data, callback) ->
      body  = base64url.decode(data.response.payload.body.data) if data.response.payload.body.size > 0
      title = ''
      date  = ''
      async.eachSeries data.response.payload.headers, (val, next) ->
        title = val.value if val.name == 'Subject'
        date  = moment(val.value).format('YYYY/MM/DD HH:mm:ss') if val.name == 'Date'

        return next(true) if title != '' && date != ''
        return next()
      , (isBreak) -> #async.eachSeries done
        asyncResult.push({title: title, date : date, snippet: data.response.snippet, body: body})
        title = ''
        date  = ''
        body  = ''
        # back to first callback eachSeries
        return data.eachCallback()

  ], (status, result) ->
    return parentCallback(status, result) if status? && status.isDone? == false
    return parentCallback(null, asyncResult)
  )

  #
  # api error handler
  # @param  {object}   err API error response
  # @param  {object}   data callback data
  # @param  {Fundtion} callback callback
  # @return {Function} args callback callback
  #
  apiErrorHandler = (err, data, callback) ->
    # token Expire over
    if err.code == 401
      OAuthClient.refreshAccessToken (err, tokens) ->
        return callback( failedRefreshAccessToken : true, err) if err?

        OAuthClient.setCredentials( access_token : tokens.access_token, refresh_token: tokens.refresh_token )

        gmail.users.messages.get data.apiParams, (err, response) ->
          return callback( { isApiError : true, apiName : 'gmail.users.messages.get'}, err) if err?
          return callback(null, { response : response, eachCallback : data.eachCallback })
    else
      return callback( { unknownError: true }, err)

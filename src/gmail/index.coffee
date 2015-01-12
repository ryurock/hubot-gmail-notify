'use strict'

module.exports = {
  #
  # google OAuth clientId
  #
  clientId: ''

  #
  # google OAuth clientSecret
  #
  clientSecret: ''

  #
  # google OAuth redirectUrl
  #
  redirectUrl: ''

  #
  # google OAuth tokens
  #
  tokens: {}

  #
  # configure 
  # 
  # @param {Object} opts google OAuth options
  # @return {Object} self
  #
  configure: (opts) ->
    throw new Error('configure error. require opts.clientId.')     unless opts.clientId?
    throw new Error('configure error. require opts.clientSecret.') unless opts.clientSecret?
    throw new Error('configure error. require opts.redirectUrl.')  unless opts.redirectUrl?
    throw new Error('configure error. require opts.tokens.')       unless opts.tokens?

    @clientId     = opts.clientId
    @clientSecret = opts.clientSecret
    @redirectUrl  = opts.redirectUrl
    @tokens       = opts.tokens
    return @

  #
  # Google Oauth Client
  # @return {OAuth2}
  #
  oAuthClient: () ->
    google    = require('googleapis')
    OAuth2    = google.auth.OAuth2
    OAuthClient = new OAuth2(@clientId, @clientSecret, @redirectUrl)
    OAuthClient.setCredentials( { access_token: @tokens.accessToken, refresh_token: @tokens.refreshToken } )
    return OAuthClient

  #
  # Google Gmail API Users.labels: list
  # @return {Function} callback
  #
  findLabelsList: require('./findLabelsList')

  #
  # Google Gmail API Users.messages: list
  # @return {Function} callback
  #
  findMessagesList: require('./findMessagesList')
}

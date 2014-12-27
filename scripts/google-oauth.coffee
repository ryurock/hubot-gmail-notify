# Description:
#   hubot Google Oauth2 commands
#
# Commands:
#   hubot google oauth generate auth url       - Generating an Google authentication URL
#   hubot google oauth set token <code>        - hubot brain set authorization tokens
#   hubot google oauth get token               - hubot brain get authorization tokens
#   hubot google oauth scope help              - Google Apis authorization scope help.
#   hubot google oauth (set|add) scope <scope> - Google Apis authorization scope list.
#
module.exports = (robot) ->

  BRAIN_KEY_TOKENS = 'google_oauth_tokens'
  BRAIN_KEY_SCOPE  = 'google_oauth_scope'

  ENV_VALID_MESSAGE_CLIEANT_ID     = 'google project required. client Id hubot cli use HUBOT_GOOGLE_CLIENT_ID={client id}'
  ENV_VALID_MESSAGE_CLIEANT_SECRET = 'google project required. client Secret hubot cli use HUBOT_GOOGLE_CLIENT_SECRET={client secret}'
  ENV_VALID_MESSAGE_REDIRECT_URL   = 'google project required. Redirect Url hubot cli use HUBOT_GOOGLE_REDIRECT_URL={redirect url}'
  ENV_VALID_MESSAGE_REDIS_URL      = 'hubot redis brain not using. hubot cli REDIS_URL=redis://127.0.0.1:6379/hubot ./bin/hubot'

  google = require('googleapis')
  OAuth2 = google.auth.OAuth2

  setOauthTokens = (tokens) ->
    return robot.brain.set BRAIN_KEY_TOKENS, tokens

  getOauthTokens = () ->
    return robot.brain.get BRAIN_KEY_TOKENS

  getScope = () ->
    return JSON.parse(robot.brain.get BRAIN_KEY_SCOPE)

  setScope = (scope) ->
    return robot.brain.set(BRAIN_KEY_SCOPE, JSON.stringify([scope]))

  addScope = (scope) ->
    scopes = getScope()
    scopes.push(scope)
    return robot.brain.set BRAIN_KEY_SCOPE, JSON.stringify(scopes)

  robot.respond /google\s*(.oauth\sgenerate\sauth\surl)?$/i, (msg) ->
    return msg.reply ENV_VALID_MESSAGE_CLIENT_ID     unless process.env.HUBOT_GOOGLE_CLIENT_ID?
    return msg.reply ENV_VALID_MESSAGE_CLIENT_SECRET unless process.env.HUBOT_GOOGLE_CLIENT_SECRET?
    return msg.reply ENV_VALID_MESSAGE_REDIRECT_URL  unless process.env.HUBOT_GOOGLE_REDIRECT_URL?

    OAuth2 = google.auth.OAuth2
    oauth2Client = new OAuth2 process.env.HUBOT_GOOGLE_CLIENT_ID, process.env.HUBOT_GOOGLE_CLIENT_SECRET, process.env.HUBOT_GOOGLE_REDIRECT_URL
    scopes = getScope()
    scopes = ['https://www.googleapis.com/auth/gmail.readonly'] unless scopes?
    url = oauth2Client.generateAuthUrl({
      access_type: 'offline',
      scope: scopes
    })
    msg.reply "Auth URL \n#{url}"


  robot.respond /google\s*(.oauth\sset\stoken)\s(.*)?$/i, (msg) ->
    return msg.reply ENV_VALID_MESSAGE_CLIENT_ID     unless process.env.HUBOT_GOOGLE_CLIENT_ID?
    return msg.reply ENV_VALID_MESSAGE_CLIENT_SECRET unless process.env.HUBOT_GOOGLE_CLIENT_SECRET?
    return msg.reply ENV_VALID_MESSAGE_REDIRECT_URL  unless process.env.HUBOT_GOOGLE_REDIRECT_URL?
    return msg.reply ENV_VALID_MESSAGE_REDIS_URL     unless process.env.REDIS_URL?

    code = msg.match[2]
    return msg.reply "oauth code not found. Please try 'hubot google oauth generate auth url" unless code?

    oauth2Client = new OAuth2(process.env.HUBOT_GOOGLE_CLIENT_ID, process.env.HUBOT_GOOGLE_CLIENT_SECRET, process.env.HUBOT_GOOGLE_REDIRECT_URL)
    oauth2Client.getToken(code, (err, tokens) ->
      return msg.reply "get token failed. reason #{err}" if err?
      setOauthTokens tokens
      return msg.reply "token set Credentials \naccess_token: #{tokens.access_token}\nrefresh_token: #{tokens.refresh_token}\nexpiry_date: #{tokens.expiry_date}"
    )

  robot.respond /google\s*(.oauth\sget\stoken)?$/i, (msg) ->
      tokens = getOauthTokens()
      return msg.reply "Google Oauth token info.\naccess_token: #{tokens.access_token}\nrefresh_token: #{tokens.refresh_token}\nexpiry_date: #{tokens.expiry_date}"

  robot.respond /google\s*(.oauth\sscope\shelp)?$/i, (msg) ->
      msg.reply "
Google Apis Authorizing OAuth2 scope list.\n
Google Apis Drive scope.        https://developers.google.com/drive/web/scopes\n
Google Apis Calender scope.     https://developers.google.com/google-apps/calendar/auth\n
Google Apis BigQuery scope.     https://cloud.google.com/bigquery/authorization\n
Google Apis Gmail scope.        https://developers.google.com/gmail/api/auth/scopes\n
more Apis.                      https://developers.google.com/apis-explorer/#p/
      "

  robot.respond /google\s*(.oauth)\s(set|add)\s(scope)\s(.*)?$/i, (msg) ->
    return msg.reply ENV_VALID_MESSAGE_CLIENT_ID     unless process.env.HUBOT_GOOGLE_CLIENT_ID?
    return msg.reply ENV_VALID_MESSAGE_CLIENT_SECRET unless process.env.HUBOT_GOOGLE_CLIENT_SECRET?
    return msg.reply ENV_VALID_MESSAGE_REDIRECT_URL  unless process.env.HUBOT_GOOGLE_REDIRECT_URL?
    return msg.reply ENV_VALID_MESSAGE_REDIS_URL     unless process.env.REDIS_URL?
    scope = msg.match[4]
    return msg.reply "oauth scope not found. Please try 'hubot google oauth scope list" unless scope?
    mode = msg.match[2]
    setScope scope if mode == 'set'
    addScope scope if mode == 'add'
    return msg.reply "Google Oauth scope set.\nscopes: #{getScope().join()}"

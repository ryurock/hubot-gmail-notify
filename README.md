# hubot-gmail-notify

[google Apis](https://code.google.com/apis/console/) Oauth2 authorization with hubot.

## Running hubot-gmail-notify Locally

You can test your hubot by running the following.

You can start hubot-gmail-notify locally by running:

```shell
export HUBOT_GOOGLE_CLIENT_ID=your google project client id
export HUBOT_GOOGLE_CLIENT_SECRET=your google project client secret
export HUBOT_GOOGLE_REDIRECT_URL=your google project redirect Url
export REDIS_URL=redis://127.0.0.1:6379/hubot
export HUBOT_SLACK_TOKEN=your slack token
bin/hubot
```


## Configuration Env


| Env Name | Description |
|---|---|
| HUBOT_GOOGLE_CLIENT_ID | Google Developers Console Project. Client ID |
| HUBOT_GOOGLE_CLIENT_SECRET | Google Developers Console Project. Client Secret |
| HUBOT_GOOGLE_REDIRECT_URL  | Google Developers Console Project. Redirect Url |
| REDIS_URL                  | [hubot brain](https://github.com/github/hubot/blob/master/docs/scripting.md#persistence) redis settings|

## Usage

Example [Gmail APIs](https://developers.google.com/gmail/api/?hl=ja) Auth authorization.

### Step1. Find Scope Page

Gmail Auth Scope Find

```
Hubot> hubot google oauth scope help
Shell: Google Apis Authorizing OAuth2 scope help.
 Google Apis Drive scope.        https://developers.google.com/drive/web/scopes
 Google Apis Calender scope.     https://developers.google.com/google-apps/calendar/auth
 Google Apis BigQuery scope.     https://cloud.google.com/bigquery/authorization
 Google Apis Gmail scope.        https://developers.google.com/gmail/api/auth/scopes
 more Apis.                      https://developers.google.com/apis-explorer/#p/
```

### Step2. Set Scope

Gmail Read Only Permission scope set

```
Hubot> hubot google oauth set scope https://www.googleapis.com/auth/gmail.readonly
Shell: Google Oauth scope set.
scopes: https://www.googleapis.com/auth/gmail.readonly
```

### Step3. generate Oauth2 Auth Page URL

```
Hubot> hubot google oauth generate auth url
Shell: Auth URL
https://accounts.google.com/o/oauth2/auth?access_type=offline&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fgmail.readonly&response_type=code&client_id={your client id}&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob
```

respond URL copy access to Browser. Google Auth ACL confirm Page push accept botton. Please keep the code that is displayed in response to the request

### Step4. set Token

```
Hubot> Hubot google oauth set token {your get code}
Hubot> Shell: token set Credentials
access_token: {access_token}
refresh_token: {refresh token}
expiry_date: 1419773035086
```

Token information is saved in hubot.brain When you run this command

### Step5. Gmail Apis Request

```shell
# find
hubot google gmail get messages list

# label Name find
hubot google gmail get messages list labelName:ecnavi_error
```

### Running hubot-gmail-notify testing mocha


```shell
export HUBOT_GOOGLE_CLIENT_ID=your google project client id
export HUBOT_GOOGLE_CLIENT_SECRET=your google project client secret
export HUBOT_GOOGLE_REDIRECT_URL=your google project redirect Url
export GOOGLE_ACCESS_TOKEN=your google API access_token
export GOOGLE_REFRESH_TOKEN=your google API refresh token
mocha --compilers coffee:coffee-script/register --recursive -R spec -t 5000
```


[Mocha](http://mochajs.org/) to Hubot Reference URL [Testable Hubot - TDDでテストを書きながらbotを作る](http://devlog.forkwell.com/2014/10/28/testable-hubot-tdddetesutowoshu-kinagarabotwozuo-ru/)

### hubot-scripts

Add the following code in your external-scripts.json file.

	% ['hubot-google-apis-oauth']
To enable scripts from the hubot-scripts package, add the script name with
extension as a double quoted string to the `hubot-scripts.json` file in this
repo.

[hubot-scripts]: https://github.com/github/hubot-scripts

### external-scripts

Hubot is able to load scripts from third-party `npm` package. Check the package's documentation, but in general it is:

1. Add the packages as dependencies into your `package.json`
2. `npm install` to make sure those packages are installed
3. Add the package name to `external-scripts.json` as a double quoted string

You can review `external-scripts.json` to see what is included by default.

##  Persistence

If you are going to use the `hubot-redis-brain` package
(strongly suggested), you will need to add the Redis to Go addon on Heroku which requires a verified
account or you can create an account at [Redis to Go][redistogo] and manually
set the `REDISTOGO_URL` variable.

    % heroku config:add REDISTOGO_URL="..."

If you don't require any persistence feel free to remove the
`hubot-redis-brain` from `external-scripts.json` and you don't need to worry
about redis at all.

[redistogo]: https://redistogo.com/

## Adapters

Adapters are the interface to the service you want your hubot to run on. This
can be something like Campfire or IRC. There are a number of third party
adapters that the community have contributed. Check
[Hubot Adapters][hubot-adapters] for the available ones.

If you would like to run a non-Campfire or shell adapter you will need to add
the adapter package as a dependency to the `package.json` file in the
`dependencies` section.

Once you've added the dependency and run `npm install` to install it you can
then run hubot with the adapter.

    % bin/hubot -a <adapter>

Where `<adapter>` is the name of your adapter without the `hubot-` prefix.

[hubot-adapters]: https://github.com/github/hubot/blob/master/docs/adapters.md

## Deployment

    % heroku create --stack cedar
    % git push heroku master

If your Heroku account has been verified you can run the following to enable
and add the Redis to Go addon to your app.

    % heroku addons:add redistogo:nano

If you run into any problems, checkout Heroku's [docs][heroku-node-docs].

You'll need to edit the `Procfile` to set the name of your hubot.

More detailed documentation can be found on the
[deploying hubot onto Heroku][deploy-heroku] wiki page.

### Deploying to UNIX or Windows

If you would like to deploy to either a UNIX operating system or Windows.
Please check out the [deploying hubot onto UNIX][deploy-unix] and
[deploying hubot onto Windows][deploy-windows] wiki pages.

[heroku-node-docs]: http://devcenter.heroku.com/articles/node-js
[deploy-heroku]: https://github.com/github/hubot/blob/master/docs/deploying/heroku.md
[deploy-unix]: https://github.com/github/hubot/blob/master/docs/deploying/unix.md
[deploy-windows]: https://github.com/github/hubot/blob/master/docs/deploying/unix.md

## Restart the bot

You may want to get comfortable with `heroku logs` and `heroku restart`
if you're having issues.

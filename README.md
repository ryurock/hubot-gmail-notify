# hubot-gmail-notify

[google Apis](https://code.google.com/apis/console/) Oauth2 authorization with hubot.

## Running hubot-gmail-notify Locally

You can test your hubot by running the following.

You can start hubot-gmail-notify locally by running:

    % export HUBOT_GOOGLE_CLIENT_ID=your google project client id
    % export HUBOT_GOOGLE_CLIENT_SECRET=your google project client secret
    % export HUBOT_GOOGLE_REDIRECT_URL=your google project redirect Url
    % export REDIS_URL=redis://127.0.0.1:6379/hubot
    % bin/hubot

## Configuration Env


| Env Name | Description |
|---|---|
| HUBOT_GOOGLE_CLIENT_ID | Google Developers Console Project. Client ID |
| HUBOT_GOOGLE_CLIENT_SECRET | Google Developers Console Project. Client Secret |
| HUBOT_GOOGLE_REDIRECT_URL  | Google Developers Console Project. Redirect Url |
| REDIS_URL                  | [hubot brain](https://github.com/github/hubot/blob/master/docs/scripting.md#persistence) redis settings|




### Running hubot-gmail-notify testing mocha

    % mocha --compilers coffee:coffee-script/register --recursive -R spec

the thing.

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

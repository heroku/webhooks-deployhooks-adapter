# Webhooks to deployhooks adapter

This app is intended as an example to aid on the migration from [Deploy Hooks](https://devcenter.heroku.com/articles/deploy-hooks) to [App Webhooks](https://devcenter.heroku.com/articles/app-webhooks).

It receives a Webhook release message, generates a message similar to the one Deploy Hooks HTTP Hook made and calls an endpoint with that payload.

Feel free to fork this repo and customize it to your needs.

## Deploy

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/heroku/webhooks-deployhooks-adapter)

Click on the deploy button and provide the requested config vars.

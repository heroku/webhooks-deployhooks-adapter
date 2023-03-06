# Webhooks to deployhooks adapter

This app is intended as an example to aid on the migration from [Deploy Hooks](https://devcenter.heroku.com/articles/deploy-hooks) to [App Webhooks](https://devcenter.heroku.com/articles/app-webhooks).

It receives a Webhook release message, generates a message similar to the one Deploy Hooks HTTP Hook made and calls an endpoint with that payload.

Keep in mind that several actions may trigger a [release](https://devcenter.heroku.com/articles/releases), you will receive a Webhook message for every release.
This is slightly different from what you received with Deploy Hooks; if you only want to receive a notification when a code change happened you need to
filter [messages](https://devcenter.heroku.com/articles/webhook-events#api-release) based on the description, code changes have a description starting with "Deploy".

Feel free to fork this repo and customize it to your needs.

## Deploy

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/heroku/webhooks-deployhooks-adapter)

Click on the deploy button and provide the requested config vars.

## Configuration

This app uses 3 config vars

### `HTTP_ENDPOINT`
This is the URL where you currently receive Deploy Hooks notifications. It will be called on every release of your app.

### `AUTHORIZATION`
You can provide this value when you create a new Webhook. Every message Webhooks send will have this value on the `Authorization` header

If you don't provide this value the Authorization header will be ignored and all messages will be accepted.

[Refer to App Webhooks' shared authorization documentation for more info](https://devcenter.heroku.com/articles/app-webhooks#using-the-shared-authorization)

### `WEBHOOK_SECRET`
This value is provided to you when you first set up a Webhook. It will be used to sign every message Webhooks send.

If you don't provide this value the digest header will be ignored and all messages will be accepted.

[Refer to App Webhooks' shared secret documentation for more info](https://devcenter.heroku.com/articles/app-webhooks#using-the-shared-secret)

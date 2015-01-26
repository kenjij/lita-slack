# lita-slack

**lita-slack** is an adapter for [Lita](https://www.lita.io/) that allows you to use the robot with [Slack](https://slack.com/). The current adapter is not compatible with pre-1.0.0 versions, as it now uses Slack's [Real Time Messaging API](https://api.slack.com/rtm).

## Installation

Add **lita-slack** to your Lita instance's Gemfile:

``` ruby
gem "lita-slack"
```

## Configuration

### Required attributes

* `token` (String) – The bot's Slack API token. Create a bot and get its token at https://my.slack.com/services/new/lita.

### Optional attributes

* `endpoint` (String) – The URL to use for the slack API.  Defaults to "https://slack.com/api".
* `proxy` (String) – Specify a HTTP proxy URL. (e.g. "http://squid.mydomain.com:3128")

**Note**: When using lita-slack, the adapter will overwrite the bot's name and mention name with the values set on the server, so `config.robot.name` and `config.robot.mention_name` will have no effect.

### config.robot.admins

Each Slack user has a unique ID that never changes even if their real name or username changes. To populate the `config.robot.admins` attribute, you'll need to use these IDs for each user you want to mark as an administrator. If you're using Lita version 4.1 or greater, you can get a user's ID by sending Lita the command `users find NICKNAME_OF_USER`.

### Example

``` ruby
Lita.configure do |config|
  config.robot.adapter = :slack
  config.robot.admins = ["U012A3BCD"]
  config.adapters.slack.token = "abcd-1234567890-hWYd21AmMH2UHAkx29vb5c1Y"
end
```

## Joining rooms

Lita will join your default channel after initial setup. To have it join additional channels or private groups, simply invite it to them via your Slack client as you would any normal user.

## Events

* `:connected` - When the robot has connected to Slack. No payload.
* `:disconnected` - When the robot has disconnected from Slack. No payload.

## License

[MIT](http://opensource.org/licenses/MIT)

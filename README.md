# Slamboo

Slamboo is a small gem that helps integrating Atlassian's Bamboo Cloud with Slack.

## Installation

```ruby
cd slamboo
gem install bundler
bundle install
rake build 
gem install pkg/slamboo-x.x.x.gem
```

And then execute:

    $ slamboo

## Commands

    slamboo message --slackURL=SLACK_URL --bambooPlanURL=BAMBOO_PLAN_URL --bambooUser=BAMBOO_USER --bambooPass=BAMBOO_PASSWORD --message=SLACK_MESSAGE --channel=SLACK_CHANNEL --user=SLACK_USER --userIconURL=SLACK_USER_ICON_URL --userEmoji=SLACK_USER_EMOJI --
    # posts a message to Slack
    # options
     --slackURL=SLACK_URL               # (mandatory) slack url with the service tokens
     --bambooDomain=BAMBOO_PLAN_URL     # (mandatory) Bamboo cloud domain
     --bamboobambooBuildResultKey=BAMBOO_BUILD_RESULD_KEY
                                        # (mandatory) this is a Bamboo plan global environment variable. Represents plan_name plan_key and build_number
     --bambooUser=BAMBOO_USER           # (mandatory) Bamboo username
     --bambooPass=BAMBOO_PASSWORD       # (mandatory) password for Bamboo user

     --message=SLACK_MESSAGE            # (optional) a message to add to success/failure message
     --channel=SLACK_CHANNEL            # (optional) a specific channel for Slamboo to post
     --user=SLACK_USER                  # (optional) username Slamboo will post
     --userIconURL=SLACK_USER_ICON_URL  # (optional) icon / avatar URL for Slamboo on Slack
     --userEmoji=SLACK_USER_EMOJI       # (optional) Slack emoji name to use as icon/avatar
     --message
     
    slamboo help [COMMAND]                                                     
    # Describe available commands
    

## Usage

    slamboo message --slackURL=SLACK_URL --bambooPlanURL=BAMBOO_PLAN_URL message=SLACK_MESSAGE --channel=SLACK_CHANNEL --user=SLACK_USER --userIconURL=SLACK_USER_ICON_URL --userEmoji=SLACK_USER_EMOJI --


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/benka/slamboo


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


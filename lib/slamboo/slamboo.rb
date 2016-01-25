require "slamboo/version"
require "slamboo/res/request"

require "net/http"
require "xmlsimple"
require "json"
require "thor"

require 'rss'
require 'open-uri'


module Slamboo
    
    ##include Resoures
    puts "Slamboo - integrate Bamboo with Slack"
    puts "Version #{VERSION}"

    class Slamboo < Thor

        # posts a message to Slack
        # options
        desc "message", "posts a message to Slack regarding the result of a Bamboo build"
        option :sURL, :type => :string, :required => true
        option :bDomain, :type => :string, :required => true
        option :bPlanKey, :type => :string, :required => true
        option :bUser, :type => :string, :required => true
        option :bPass, :type => :string, :required => true
        option :message, :type => :string, :required => false
        option :channel, :type => :string, :required => false
        option :user, :type => :string, :required => false
        option :userIconURL, :type => :string, :required => false
        option :userEmoji, :type => :string, :required => false
     
        def message
            bambooURL=options[:bDomain]
            bambooKEY=options[:bPlanKey]

            uriStringBamboo = "https://#{bambooURL}/builds/rest/api/latest/result/#{bambooKEY}"
            uriBamboo = URI(uriStringBamboo)

            r = Resources::Request.new(uriBamboo, options[:bUser], options[:bPass])
            req=r.create_get_request_header

            res = Net::HTTP.start(uriBamboo.hostname, 
                :use_ssl => uriBamboo.scheme == 'https') { |http|
                http.request(req)
            }

            if res.code != "200"
                puts res.code
                puts res.message
            else 
                result = XmlSimple.xml_in res.body
                #puts result.keys
               
                puts result["key"]
                puts result['planName'][0]
                puts result["projectName"][0]
                puts result["buildNumber"][0]
                puts result["buildState"][0]
                reasonSummary = result["reasonSummary"][0].gsub! "a href=\"", ""
                reasonSummary = reasonSummary.gsub! "\">", "|"
                reasonSummary = reasonSummary.gsub! "</a>", ">"
                puts result["reasonSummary"]

                rand = Random.new

                emojiSuccess = [":white_check_mark:", ":eight_spoked_asterisk:", ":bowtie:", ":sunglasses:", ":+1:", ":champagne:", ":guinnes:", ":beer:", ":lollipop:", ":candy:", ":beers:"]
                emojiFail = [":trollface:", ":bangbang:", "::", ":do_not_litter:", ":x:", ":no_entry_sign:", ":name_badge:", ":no_entry:", ":sos:", ":broken_heart:", ":fire:", ":rage:", ":sob:"]

                
                result["buildState"][0] == "Failed" ? resultEmoji = emojiFail[rand.rand(emojiFail.length)] : resultEmoji = emojiSuccess[rand.rand(emojiSuccess.length)] 
                slackMsg = JSON.parse("{}")

                options[:user] != nil ? slackMsg["username"] = options[:user] : nil
                options[:channel] != nil ? slackMsg["channel"] = "\##{options[:channel]}" : nil
                options[:userIconURL] != nil ? slackMsg["icon_url"] = options[:userIconURL] : nil
                options[:userEmoji] != nil ? slackMsg["icon_emoji"] = options[:userEmoji] : nil

                slackMsg["text"] = "#{resultEmoji} <https://#{bambooURL}/builds/browse/#{result["key"]}|#{result["projectName"][0]} &gt; #{result['planName'][0]} &gt; #{result["buildNumber"][0]} > *#{result["buildState"][0]}*\n#{result["reasonSummary"][0]}"
                puts ">>>>>>>>>>>>>>>>>>>>>>"
                puts slackMsg
                puts ">>>>>>>>>>>>>>>>>>>>>>"

                #options[:message] != nil ? msg = options[:message] : nil

                slackURL=options[:sURL]
                uriStringSlack = slackURL
                uriSlack = URI(uriStringSlack)

                s = Resources::Request.new(uriSlack, nil, nil)
                sreq = s.create_post_request_header(JSON.generate(slackMsg))

                sres = Net::HTTP.start(uriSlack.hostname, 
                    :use_ssl => uriSlack.scheme == 'https') { |http|
                    http.request(sreq)
                }
                if sres.code != "200"
                    puts sres.code
                else
                    puts sres
                end

            end

=begin
                ur = "https://#{bambooURL}/builds/rss/createAllBuildsRssFeed.action?feedType=rssAll&os_authType=basic"
                open(ur) do |rss|
                  feed = RSS::Parser.parse(rss)
                  puts "Title: #{feed.channel.title}"
                  feed.items.each do |item|
                    puts item
                    puts "Item: #{item.title}"
                  end
                end
=end


        end
    end
end
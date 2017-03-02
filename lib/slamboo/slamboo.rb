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
        option :failedChannel, :type => :string, :required => false
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

                slackMsg = JSON.parse("{}")

                options[:user] != nil ? slackMsg["username"] = options[:user] : nil
                options[:channel] != nil ? slackMsg["channel"] = "\##{options[:channel]}" : nil
                options[:userIconURL] != nil ? slackMsg["icon_url"] = options[:userIconURL] : nil
                options[:userEmoji] != nil ? slackMsg["icon_emoji"] = options[:userEmoji] : nil

                rand = Random.new

                emojiSuccess = [":white_check_mark:", ":eight_spoked_asterisk:", ":bowtie:", ":sunglasses:", ":+1:"]
                emojiFail = [":trollface:", ":bangbang:", ":x:", ":do_not_litter:", ":x:", ":no_entry_sign:", ":no_entry:", ":sos:"]
                
                if (result["buildState"][0] == "Failed")
                    resultEmoji = emojiFail[rand.rand(emojiFail.length)]
                    resultColor = "#E02D19"
                    options[:failedChannel] != nil ? slackMsg["channel"] = "\##{options[:failedChannel]}" : nil
                else
                    resultEmoji = emojiSuccess[rand.rand(emojiSuccess.length)] 
                    resultColor = "#0DB542"
                end

                #slackMsg["text"] = "> #{resultEmoji} <https://#{bambooURL}/builds/browse/#{result["key"]}|#{result["projectName"][0]} &gt; #{result['planName'][0]} &gt; #{result["buildNumber"][0]} > *#{result["buildState"][0]}*\n> #{result["reasonSummary"][0]}"
                slackMsg["attachments"] = []
                slackMsg["attachments"][0] = JSON.parse("{}")
                #slackMsg["attachments"][0]["fallback"] ="#{resultEmoji} <https://#{bambooURL}/builds/browse/#{result["key"]}|#{result["projectName"][0]} &gt; #{result['planName'][0]} &gt; #{result["buildNumber"][0]} > *#{result["buildState"][0]}*\n> #{result["reasonSummary"][0]}"
                slackMsg["attachments"][0]["fallback"] ="#{result["buildState"][0]} &gt; #{result['planName'][0]}"
                #slackMsg["attachments"][0]["pretext"] = "#{resultEmoji} #{result['planName'][0]}"
                slackMsg["attachments"][0]["title"] = "#{result["projectName"][0]} &gt; #{result['planName'][0]}"
                slackMsg["attachments"][0]["title_link"] = "https://#{bambooURL}/builds/browse/#{result["key"]}"
                slackMsg["attachments"][0]["fields"] = []
                slackMsg["attachments"][0]["fields"][0] = JSON.parse("{}")
                slackMsg["attachments"][0]["fields"][0]["title"] = result["buildState"][0]
                slackMsg["attachments"][0]["fields"][0]["value"] = "Build number: #{result["buildNumber"][0]}"
                slackMsg["attachments"][0]["fields"][0]["short"] = true
                slackMsg["attachments"][0]["fields"][1] = JSON.parse("{}")
                slackMsg["attachments"][0]["fields"][1]["title"] = "Reason:"
                slackMsg["attachments"][0]["fields"][1]["value"] = result["reasonSummary"][0]
                slackMsg["attachments"][0]["fields"][1]["short"] = true
                slackMsg["attachments"][0]["color"] = resultColor
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
        end

        desc "message-fail", "posts a 'FAIL' message straight to Slack"
        option :sURL, :type => :string, :required => true
        option :channel, :type => :string, :required => true
        option :user, :type => :string, :required => true
        option :userEmoji, :type => :string, :required => true

        option :ciURL, :type => :string, :required => true
        option :planName, :type => :string, :required => true
        option :buildNumber, :type => :string, :required => true
        option :triggerHash, :type => :string, :required => true
        option :triggerUser, :type => :string, :required => true
        option :pipelineGroup, :type => :string, :required => true
     
        def message_fail
            slackMsg = JSON.parse("{}")
            ci = JSON.parse("{}")

            options[:user] != nil ? slackMsg["username"] = options[:user] : nil
            options[:channel] != nil ? slackMsg["channel"] = "\##{options[:channel]}" : nil
            options[:userEmoji] != nil ? slackMsg["icon_emoji"] = options[:userEmoji] : nil

            options[:ciURL] != nil ? ci["ciURL"] = options[:ciURL] : nil
            options[:planName] != nil ? ci["planName"] = options[:planName] : nil
            options[:buildNumber] != nil ? ci["buildNumber"] = options[:buildNumber] : nil
            options[:triggerHash] != nil ? ci["triggerHash"] = options[:triggerHash] : nil
            options[:triggerUser] != nil ? ci["triggerUser"] = options[:triggerUser] : nil
            options[:pipelineGroup] != nil ? ci["pipelineGroup"] = options[:pipelineGroup] : nil


            resultColor = "#E02D19"

            slackMsg["attachments"] = []
            slackMsg["attachments"][0] = JSON.parse("{}")
            slackMsg["attachments"][0]["fallback"] ="Failed &gt; #{ci["pipelineGroup"]} &gt; #{ci["planName"]} | by #{ci["triggerUser"]}, hash \##{ci["triggerHash"]}"
            slackMsg["attachments"][0]["title"] = "#{ci["pipelineGroup"]} &gt; #{ci["planName"]}"
            slackMsg["attachments"][0]["title_link"] = "#{ci["ciURL"]}/go/pipelines/value_stream_map/#{ci["planName"]}/#{ci["buildNumber"]}"

            slackMsg["attachments"][0]["fields"] = []
            slackMsg["attachments"][0]["fields"][0] = JSON.parse("{}")
            slackMsg["attachments"][0]["fields"][0]["title"] = "Failed"
            slackMsg["attachments"][0]["fields"][0]["value"] = "Build number: #{ci["buildNumber"]}"
            slackMsg["attachments"][0]["fields"][0]["short"] = true
            slackMsg["attachments"][0]["fields"][1] = JSON.parse("{}")
            slackMsg["attachments"][0]["fields"][1]["title"] = "Reason:"
            slackMsg["attachments"][0]["fields"][1]["value"] = "by: #{ci["triggerUser"]}, hash: #{ci["triggerHash"]}"
            slackMsg["attachments"][0]["fields"][1]["short"] = true
            slackMsg["attachments"][0]["color"] = resultColor
            puts ">>>>>>>>>>>>>>>>>>>>>>"
            puts slackMsg
            puts ">>>>>>>>>>>>>>>>>>>>>>"

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


        desc "message-success", "posts a 'SUCCESS' message straight to Slack"
        option :sURL, :type => :string, :required => true
        option :channel, :type => :string, :required => true
        option :user, :type => :string, :required => true
        option :userEmoji, :type => :string, :required => true

        option :message, :type => :string, :required => false
        option :messageUrl, :type => :string, :required => false
        option :messageIcon, :type => :string, :required => false

        option :ciURL, :type => :string, :required => true
        option :planName, :type => :string, :required => true
        option :buildNumber, :type => :string, :required => false
        option :pipelineGroup, :type => :string, :required => false
     
        def message_success
            slackMsg = JSON.parse("{}")
            ci = JSON.parse("{}")

            options[:user] != nil ? slackMsg["username"] = options[:user] : nil
            options[:channel] != nil ? slackMsg["channel"] = "\##{options[:channel]}" : nil
            options[:userEmoji] != nil ? slackMsg["icon_emoji"] = options[:userEmoji] : nil
            options[:ciURL] != nil ? ci["ciURL"] = options[:ciURL] : nil

            options[:planName] != nil ? ci["planName"] = options[:planName] : nil
            options[:buildNumber] != nil ? ci["buildNumber"] = "`#" + options[:buildNumber] + "`" : nil

            options[:pipelineGroup] != nil ? ci["pipelineGroup"] = options[:pipelineGroup] + " &gt;": nil
            options[:message] != nil ? ci["message"] = options[:message] : nil
            options[:messageUrl] != nil ? ci["messageUrl"] = options[:messageUrl] : nil
            options[:messageIcon] != nil ? ci["messageIcon"] = options[:messageIcon] : nil


            resultColor = "#0DB542"

            slackMsg["attachments"] = []
            slackMsg["attachments"][0] = JSON.parse("{}")
            slackMsg["attachments"][0]["fallback"] = "SUCCESS &gt; #{ci["planName"]}"
            slackMsg["attachments"][0]["text"] = "*Success:* #{ci["pipelineGroup"]} #{ci["planName"]} #{ci["buildNumber"]}"
            slackMsg["attachments"][0]["mrkdwn_in"] = "text",
            slackMsg["attachments"][0]["author_name"] = "#{ci["message"]}",
            slackMsg["attachments"][0]["author_link"] = "#{ci["messageUrl"]}",
            slackMsg["attachments"][0]["author_icon"] = "#{ci["messageIcon"]}"
            slackMsg["attachments"][0]["color"] = resultColor
            puts ">>>>>>>>>>>>>>>>>>>>>>"
            puts slackMsg
            puts ">>>>>>>>>>>>>>>>>>>>>>"

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
    end
end
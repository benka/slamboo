require "slamboo/version"
require "slamboo/res/request"

require "net/http"
require "json"
require "thor"

module Slamboo
    
    ##include Resoures
    puts "Slamboo - integrate Bamboo with Slack"
    puts "Version #{VERSION}"

    class Slamboo < Thor

        # posts a message to Slack
        # options
        desc "message", "posts a message to Slack regarding the result of a Bamboo build"
        option :slackURL, :type => :string, :required => true
        option :bambooDomain, :type => :string, :required => true
        option :bambooBuildResultKey, :type => :string, :required => true
        option :bambooUser, :type => :string, :required => true
        option :bambooPass, :type => :string, :required => true
        option :message, :type => :string, :required => false
        option :channel, :type => :string, :required => false
        option :user, :type => :string, :required => false
        option :userIconURL, :type => :string, :required => false
        option :userEmoji, :type => :string, :required => false
     
        def message
            bambooURL=options[:bambooDomain]
            bambooKEY=options[:bambooBuildResultKey]
            slackURL=options[:slackURL]

            uriStringBamboo = "https://#{bambooURL}/builds/rest/api/latest/result/#{bambooKEY}"
            uri = URI(uriStringBamboo)

            r = Resources::Request.new(uri, options[:bambooUser], options[:bambooPass])
            req=r.create_get_request_header

            res = Net::HTTP.start(uri.hostname, 
                :use_ssl => uri.scheme == 'https') { |http|
                http.request(req)
            }

            if res.code != "200"
                puts res.code
                puts res.message
            else 
                result=JSON.parse(res.body)

                puts res.body
                
#                result.each { |i|
                    #puts "Filter name: #{i["name"]},  ID: #{i["id"]}"
                    #puts "Filter URL: #{i["searchUrl"]}"
                    #puts "-------------------------------"
                #}
            end
        end
    end
end
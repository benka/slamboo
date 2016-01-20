module Slamboo
    module Resources

        class Request

            def initialize(uri, user, pwd)
                @uri = uri
                @user = user
                @pwd = pwd
            end

            def create_get_request_header
                req = Net::HTTP::Get.new(@uri)
                req.basic_auth @user, @pwd
                req.content_type = 'application/json'
                req.add_field 'X-Atlassian-Token' ,'nocheck'
                return req
            end

            def create_post_request_header(post)
                req = Net::HTTP::Post.new(@uri)
                req.basic_auth @user, @pwd
                req.content_type = 'application/json'
                req.add_field 'X-Atlassian-Token' ,'nocheck'
                req.body=post
                return req
            end            
        end
    end
end
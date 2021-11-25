require 'net/http'
require 'uri'
require 'json'

class LineAPI

  def self.bot_join(line_group_id)
    uri = URI.parse("https://api.line.me/v2/bot/group/#{line_group_id}/summary")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{ENV['LINE_CHANNEL_TOKEN']}"
    req_options = {
      use_ssl: uri.scheme == "https",
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    res = JSON.parse(response.body)
    res['groupName']
  end

end

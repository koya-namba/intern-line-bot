require 'json'
require 'net/http'
require 'uri'

class FoodSearchAPI

    def self.search(place, food)
        data = {
          "key": ENV['API_KEY'], 
          "address": place,
          "keyword": food
        }
        query = data.to_query
        uri = URI("http://webservice.recruit.co.jp/hotpepper/gourmet/v1/?" + query)
        http = Net::HTTP.new(uri.host, uri.port)
        req = Net::HTTP::Get.new(uri)
        res = http.request(req)
        Hash.from_xml(res.body)
    end

end

require 'json'
require 'line/bot'
require 'net/http'
require 'uri'

class WebhookController < ApplicationController
  protect_from_forgery except: [:callback] # CSRF対策無効化

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  # 飲食店検索
  def food_search_api(place, food)
    data = {
      "key": "01458b22b6dce274",
      "address": place,
      "keyword": food
    }
    query = data.to_query
    uri = URI("http://webservice.recruit.co.jp/hotpepper/gourmet/v1/?" + query)
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri)
    res = http.request(req)
    res_data = Hash.from_xml(res.body)
    return res_data
  end

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head 470
    end

    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          text = event.message['text'].split("、")
          place = text[0]
          food = text[1]
          res_data = food_search_api(place, food)

          hello_content = <<~EOS
          久しぶり〜！今度みんなでご飯でもどう？
          #{place}でお勧めの#{food}を紹介するね！
          EOS

          message = {
            type: 'text',
            text: hello_content
          }
          client.push_message(ENV['GROUP_ID'], message)

          for i in 0..2 do
            recommend_store = <<~EOS
            店名： #{res_data['results']['shop'][i]['name']}
            最寄駅： #{res_data['results']['shop'][i]['station_name']}
            URL： #{res_data['results']['shop'][i]['urls']['pc']}
            EOS
            message = {
              type: 'text',
              text: recommend_store
            }
            client.push_message(ENV['GROUP_ID'], message)
          end
        
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
      end
    }
    head :ok
  end
end

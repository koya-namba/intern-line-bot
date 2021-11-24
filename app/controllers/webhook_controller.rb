require 'json'
require 'line/bot'
require 'net/http'
require 'uri'

require './app/models/create_content'
require './app/models/food_search_api'
require './app/models/message_analysis'

class WebhookController < ApplicationController
  protect_from_forgery except: [:callback] # CSRF対策無効化

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
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
          # 個人チャットから「場所，料理」を取得
          place, food = MessageAnalysis.analysis(event.message['text'])

          # 場所，料理からお勧めの飲食店を検索
          res_data = FoodSearchAPI.search(place, food)

          # お勧め飲食店が3店舗以上ある場合
          if res_data["results"]["results_returned"].to_i >= 3

            # グループチャットに久々メッセージ送信
            greeting = CreateContent.greeting(place, food)
            client.push_message(ENV['GROUP_ID'], greeting)

            # グループチャットにお勧め飲食店を送信
            messages = CreateContent.recommend_store(res_data)
            puts messages
            messages.each do |message|
              client.push_message(ENV['GROUP_ID'], message)
            end
          else
            # お勧め店舗が2店舗以下の場合，挨拶のみ
            greeting_only = CreateContent.greeting_only
            client.push_message(ENV['GROUP_ID'],greeting_only)
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

require 'line/bot'

class WebhookController < ApplicationController
  STATE = 0
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

          if event.message['text'] == "お久しぶり"
            group_names = []
            line_user_id = event['source']['userId']
            @user = User.find_by(line_user_id: line_user_id)
            @user.group_users.each do |group_user|
              group_names.push(group_user.group.name)
            end
            message = CreateContent.recommend_group(group_names)
            client.push_message(line_user_id, message)
            message = CreateContent.sample_message
            client.push_message(line_user_id, message)
          end

          if event.message['text'].start_with?("メッセージ")
            group_name, place, food = MessageAnalysis.analysis(event.message['text'])
            @group = Group.find_by(name: group_name)
            line_group_id = @group.line_group_id
            # 場所，料理からお勧めの飲食店を検索
            res_data = FoodSearchAPI.search(place, food)
            # お勧め飲食店が1店舗以上ある場合
            if res_data["results"]["results_returned"].to_i >= 1

              # グループチャットに久々メッセージ送信
              greeting = CreateContent.greeting(place, food)
              client.push_message(line_group_id, greeting)

              # グループチャットにお勧め飲食店を送信
              messages = CreateContent.recommend_store(res_data)
              messages.each do |message|
                client.push_message(line_group_id, message)
              end
            else
              # お勧め店舗が0店舗以下の場合，挨拶のみ
              greeting_only = CreateContent.greeting_only
              client.push_message(line_group_id, greeting_only)
            end
            
          end
        
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end

      when Line::Bot::Event::MemberJoined
        line_group_id = event['source']['groupId']
        event['joined']['members'].each do |member|
          line_user_id = member['userId']
          res = JSON.parse(client.get_group_member_profile(line_group_id, line_user_id).body)
          display_name = res['displayName']
          @user = User.find_or_initialize_by(line_user_id: line_user_id, display_name: display_name)
          if @user.new_record?
            @user.save
          end
          @group = Group.find_by(line_group_id: line_group_id)
          begin
            @group.users << @user
          rescue => e
            puts e
          end
        end

      when Line::Bot::Event::Join
        line_group_id = event['source']['groupId']
        group_name = LineAPI.bot_join(line_group_id)
        @group = Group.new(line_group_id: line_group_id, name: group_name)
        begin
          @group.save
        rescue => e
          puts e
        end
      end

    }
    head :ok
  end
end

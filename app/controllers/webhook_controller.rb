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

          # グループに自分を登録
          if event.message['text'] == "自分を登録"
            line_user_id = event['source']['userId']
            line_group_id = event['source']['groupId']
            res = JSON.parse(client.get_group_member_profile(line_group_id, line_user_id).body)
            display_name = res['displayName']
            @user = User.find_or_create_by(line_user_id: line_user_id, display_name: display_name)
            @group = Group.find_by(line_group_id: line_group_id)
            begin
              # 今いるグループと自分を結ぶ
              @group.users << @user
              client.push_message(line_group_id, CreateContent.register_me)
            rescue => e
              client.push_message(line_group_id, CreateContent.already_registered)
              puts e
            end
          
          # メッセージが「お久しぶり」の場合，グループ一覧を送信する
          elsif event.message['text'] == "お久しぶり"
            group_names = []
            line_user_id = event['source']['userId']
            begin
              # ユーザが見つかった場合
              @user = User.find_by(line_user_id: line_user_id)
              @user.group_users.each do |group_user|
                group_names.push(group_user.group.name)
              end
              client.push_message(line_user_id, CreateContent.recommend_group(group_names))
              client.push_message(line_user_id, CreateContent.sample_message)
            rescue => e
              # ユーザが見つからなかった場合
              client.push_message(line_user_id, CreateContent.group_not_found)
              puts e
            end
          
          # メッセージが「メッセージ」から始まる場合，指定グループにお勧め飲食店を送信する
          elsif event.message['text'].start_with?("メッセージ")
            group_name, place, food = MessageAnalysis.analysis(event.message['text'])
            @group = Group.find_by(name: group_name)
            line_group_id = @group.line_group_id
            # 場所，料理からお勧めの飲食店を検索
            res_data = FoodSearchAPI.search(place, food)
            # お勧め飲食店が1店舗以上ある場合
            if res_data["results"]["results_returned"].to_i >= 1

              # グループチャットに挨拶メッセージ送信
              greeting = CreateContent.greeting(place, food)
              client.push_message(line_group_id, greeting)

              # グループチャットにお勧め飲食店を送信
              messages = CreateContent.recommend_store(res_data)
              messages.each do |message|
                client.push_message(line_group_id, message)
              end
            else
              # お勧め店舗が0店舗以下の場合，挨拶のみを送信
              greeting_only = CreateContent.greeting_only
              client.push_message(line_group_id, greeting_only)
            end
          
          # メッセージが「使い方」の場合，使い方を送信
          elsif event.message['text'] == "使い方" && event['source']['groupId'] == nil
            line_user_id = event['source']['userId']
            client.push_message(line_user_id, CreateContent.how_to_use)

          # 上記以外のメッセージに反応する
          elsif event['source']['groupId'] == nil
            line_user_id = event['source']['userId']
            client.push_message(line_user_id, CreateContent.idle_talk)

          end
        
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end

      # BotがいるグループにユーザがJoinした場合，そのユーザを登録する
      when Line::Bot::Event::MemberJoined
        line_group_id = event['source']['groupId']
        event['joined']['members'].each do |member|
          line_user_id = member['userId']
          res = JSON.parse(client.get_group_member_profile(line_group_id, line_user_id).body)
          display_name = res['displayName']
          @user = User.find_or_create_by(line_user_id: line_user_id, display_name: display_name)
          @group = Group.find_by(line_group_id: line_group_id)
          begin
            # 今いるグループとユーザを結ぶ
            @group.users << @user
          rescue => e
            puts e
          end
        end

      # BotがグループにJoinした場合，そのグループをテーブルに登録
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

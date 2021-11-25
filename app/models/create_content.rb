class CreateContent
    # 表示数を設定
    LIMIT = 3

    def self.greeting_only
        # 挨拶メッセージ作成
        greeting = <<~EOS
        久しぶり〜！今度みんなでご飯でもどう？
        EOS
        message = {
            type: 'text',
            text: greeting
        }
    end

    def self.greeting(place, food)
        # 挨拶メッセージ作成
        greeting = <<~EOS
        久しぶり〜！今度みんなでご飯でもどう？
        #{place}でお勧めの#{food}を紹介するね！
        EOS
        message = {
            type: 'text',
            text: greeting
        }
    end

    def self.recommend_store(res_data)
        # お勧め飲食店メッセージ作成
        messages = []
        shops = res_data['results']['shop']
        shops.first(LIMIT).each do |shop|
            recommend_store = <<~EOS
            店名： #{shop['name']}
            最寄駅： #{shop['station_name']}
            URL： #{shop['urls']['pc']}
            EOS
            message = {
              type: 'text',
              text: recommend_store
            }
            messages.push(message)
        end
        messages
    end
end

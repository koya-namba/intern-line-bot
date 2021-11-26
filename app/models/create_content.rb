class CreateContent
  # 表示数を設定
    LIMIT = 3

  # グループに送信するメッセージ

  def self.greeting_only
    # 挨拶メッセージ作成
    greeting = <<~EOS
    久しぶり！
    今度みんなでご飯でもどう？
    EOS
    message = {
      type: 'text',
      text: greeting
    }
  end

  def self.greeting(place, food)
    # 挨拶メッセージ作成
    greeting = <<~EOS
    久しぶり！
    今度みんなでご飯でもどう？
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

  # 個人チャットに送信するメッセージ

  def self.register_me
    # グループに自分の登録が完了したときのメッセージ
    register_me = <<~EOS
    登録が完了しました！
    EOS
    message = {
      type: 'text',
      text: register_me
    }
  end

  def self.already_registered
    # グループに自分が既に登録されているときのメッセージ
    already_registered = <<~EOS
    登録済みです！
    EOS
    message = {
      type: 'text',
      text: already_registered
    }
  end

  def self.recommend_group(group_names)
    # グループ一覧のメッセージ
    recommend_group = <<~EOS
    お久しぶり！
    グループを選んで、
    例を参考にメッセージを送ってね！
    
    グループ一覧
    --------------------------------
    #{group_names.join("\n")}
    --------------------------------
    EOS
    message = {
      type: 'text',
      text: recommend_group
    }
  end

  def self.sample_message
    # グループ，場所，料理を送信するメッセージのサンプル
    sample_message = <<~EOS
    メッセージ
    [グループ名]
    [場所，料理]

    (例)
    メッセージ
    高校サッカー部
    船橋、焼肉
    EOS
    message = {
      type: 'text',
      text: sample_message
    }
  end

  def self.group_not_found
    # 個人とグループが結びついていない時のメッセージ
    group_not_found = <<~EOS
    グループが見つかりませんでした．
    EOS
    message = {
      type: 'text',
      text: group_not_found
    }
  end

  def self.how_to_use
    # 使い方のメッセージ
    how_to_use = <<~EOS
    「What's new」は、
    久々に会いたいグループに
    君に代わって飲食店を紹介するよ

    まずは、
    「お久しぶり」
    とメッセージを送ってね！
    EOS
    message = {
      type: 'text',
      text: how_to_use
    }
  end

  def self.idle_talk
    # 適当なメッセージ
    idle_talk = <<~EOS
    ヤッホーい！
    最近調子はどう？

    使い方がわからなかったら、
    「使い方」
    とメッセージを送ってね！
    EOS
    message = {
      type: 'text',
      text: idle_talk
    }
  end
end

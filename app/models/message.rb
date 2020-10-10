class Message
  TOKYO_CITY_FORECAST_URL = 'https://www.drk7.jp/weather/xml/13.xml'
  COMPLIMENTS = %w(素敵 ステキ すてき 面白い おもしろい ありがと すごい スゴイ スゴい 好き 頑張 がんば ガンバ 筋肉  バルク プロテイン ジム アミノ酸 マッチョ 格好 カッコ良い たくましい 逞 イケメン).freeze
  GREETINGS = %w(こんにちは こんばんは 初めまして はじめまして おはよう).freeze

  def initialize(client, event)
    @client = client
    @event = event
  end

  def deliver
    user_message = @event.message['text']
    forecast_raw_data = open(TOKYO_CITY_FORECAST_URL).read.toutf8
    forecast = REXML::Document.new(forecast_raw_data)

    message =
      case @event.type
      when Line::Bot::Event::MessageType::Text
        case user_message
        when /.*(明日|あした).*/
          TomorrowMessage.new(forecast).generate_message
        when /.*(明後日|あさって).*/
          DayAfterTomorrowMessage.new(forecast).generate_message
        when Regexp.new(".*(#{COMPLIMENTS.join('|')}).*")
          <<~TEXT
            ありがとな！
            ちょっと、嬉しいじゃねえか...
          TEXT
        when Regexp.new(".*(#{GREETINGS.join('|')}).*")
          "よう、元気か？\n声をかけてくれてありがとな！\n今日もしっかりジムに行って汗を流そうぜ！"
          <<~TEXT
            よう、元気か？
            声をかけてくれてありがとな！
            今日もしっかりジムに行って汗を流そうぜ！
          TEXT
        else
          TodayMessage.new(forecast).generate_message
        end
      else
        'ぐぬぬ...テキスト以外は解せぬ'
      end

    @client.reply_message(@event['replyToken'], {type: 'text', text: message.chomp})
  end
end

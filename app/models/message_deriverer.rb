class Message
  TOKYO_CITY_FORECAST_URL = 'https://www.drk7.jp/weather/xml/13.xml'
  COMPLIMENTS = %w(素敵 ステキ すてき 面白い おもしろい ありがと すごい スゴイ スゴい 好き 頑張 がんば ガンバ 筋肉  バルク プロテイン ジム アミノ酸 マッチョ 格好 カッコ良い たくましい 逞 イケメン).freeze
  GREETINGS = %w(こんにちは こんばんは 初めまして はじめまして おはよう).freeze

  def initialize(client, event)
    @client = client
    @event = event
  end

  def deliver
    user_message = event.message['text']
    forecast_raw_data = open(TOKYO_CITY_FORECAST_URL).read.toutf8
    forecast = REXML::Document.new(forecast_raw_data)

    message =
      case event.type
      when Line::Bot::Event::MessageType::Text
        case user_message
        when /.*(明日|あした).*/
          TomorrowMessage.new(forecast).generate_message
        when /.*(明後日|あさって).*/
          DayAfterTomorrowMessage.new(forecast).generate_message
        when Regexp.new(".*(#{COMPLIMENTS.join('|')}).*")
          "ありがとな！\nちょっと、嬉しいじゃねえか..."
        when Regexp.new(".*(#{GREETINGS.join('|')}).*")
          "よう、元気か？\n声をかけてくれてありがとな！\n今日もしっかりジムに行って汗を流そうぜ！"
        else
          TodayMessage.new(forecast).generate_message
        end
      else
        'ぐぬぬ...テキスト以外は解せぬ'
      end

    client.reply_message(event['replyToken'], {type: 'text', text: message})
  end
end

module ForecastMessageGenerator
  TOKYO_AREA_PATH = 'weatherforecast/pref/area[4]/'
  DATE_NUMBERS = {today: 1, tommorrow: 2, day_after_tomorrow: 3}
  FORECAST_DATA_NUMBERS = {first: 1, second: 2, thrid: 3, fourth: 4}
  MINIMUM_RAINY_PERCENT = 30

  def initialize_forecast
    @rainy_percent_06to12, @rainy_percent_12to18, @rainy_percent_18to24 = forecast_datum(forecast, DATE_NUMBERS[:day_after_tomorrow])
  end

  def forecast_datum(forecast, date)
    FORECAST_DATA_NUMBERS.values[1..3].map {|forecast_number| forecast.elements[TOKYO_AREA_PATH + "info[#{@date_number}]/rainfallchance/period[#{forecast_number}]"].text.to_i }
  end

  def rainy?
    [@rainy_percent_06to12, @rainy_percent_12to18, @rainy_percent_18to24].any? {|data| data >= MINIMUM_RAINY_PERCENT}
  end

  def generate_message
    rainy? ? : rainy_message : sunny_message
  end

  def formatted_date
    @date.strftime("%m月%d日")
  end
end

class TomorrowMessage
  include ForecastMessageGenerator

  def initialize
    @date_number = DATE_NUMBERS[:tommorrow]
    @date = Time.current.to_date.next_day
    initialize_forecast
  end

  def rainy_message
    <<~TEXT
      明日(#{formatted_date})は雨が降りそうだぞ。
      雨が降ってもジムには行こうな！
      今のところの降水確率はこんな感じだ。
        06〜12時　#{rainy_percent_06to12}％
        12〜18時　#{rainy_percent_12to18}％
        18〜24時　#{rainy_percent_18to24}％
      また明日の朝の最新の天気予報で雨が降りそうだったら教えるな！
    TEXT
  end

  def rainy_message
    <<~TEXT
      明日(#{formatted_date})は雨が降りそうだぞ。
      雨が降ってもジムには行こうな！
      今のところの降水確率はこんな感じだ。
      　06〜12時　#{rainy_percent_06to12}％
      　12〜18時　#{rainy_percent_12to18}％
      　18〜24時　#{rainy_percent_18to24}％
      また明日の朝の最新の天気予報で雨が降りそうだったら教えるな！
    TEXT
  end

  def sunny_message
    <<~TEXT
      明日(#{formatted_date})は雨が降らない予定だぞ！
      ジムまでランニングで行けるな。
      また明日の朝の最新の天気予報で雨が降りそうだったら教えるぜ！
    TEXT
  end
end

class TodayMessage
  include ForecastMessageGenerator

  def initialize
    @date_number = DATE_NUMBERS[:today]
    @date = Time.current.to_date
    initialize_forecast
  end

  def rainy_message
    comment_in_message =
      [
        "雨が降っているということは、ジムが空いているぞ。チャンスだ！",
        "雨に負けずテストステロン全開で行こうぜ！",
        "雨だけどジムにはしっかり行こうな！"
      ].sample

    <<~TEXT
      今日(#{time1.strftime("%m月%d日")})の天気？
      雨が降りそうだから折りたたみ傘とサラダチキン持って行けよ！
      　06〜12時　#{rainy_percent_06to12}％
      　12〜18時　#{rainy_percent_12to18}％
      　18〜24時　#{rainy_percent_18to24}％
      #{comment_in_message}
    TEXT
  end

  def sunny_message
    comment_in_message =
      [
        "ジムまでランニングで行けるな！",
        "たまには日焼けも良いかもな！",
        "筋トレしてバルクアップ目指そうぜ！",
        "雨が降ったらごめんな！"
      ].sample

    <<~TEXT
      今日(#{time1.strftime("%m月%d日")})の天気？
      雨は降らなさそうだよ。
      #{comment_in_message}
    TEXT
  end
end

class DayAfterTomorrowMessage
  include ForecastMessageGenerator

  def initialize
    @date_number = DATE_NUMBERS[:day_after_tomorrow]
    @date = Time.current.to_date.next_day(2)
    initialize_forecast
  end

  def rainy_message
    <<~TEXT
      明後日(#{formatted_date})は雨が降りそうだ…
      たまには家で自重トレーニングも良いだろうな。
      当日の朝に雨が降りそうだったら教えるぞ！
    TEXT
  end

  def sunny_message
    <<~TEXT
      明後日(#{formatted_date})の天気か？
      気が早いな！
      明後日は雨が降らない予定だぞ。
      また当日の朝の最新の天気予報で雨が降りそうだったら教えるからな！
    TEXT
  end
end

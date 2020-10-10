class TomorrowMessage
  include MessageGenerator

  def initialize(forecast)
    @date_number = DATE_NUMBERS[:tommorrow]
    @date = Time.current.to_date.next_day
    initialize_forecast(forecast)
  end

  def rainy_message
    <<~TEXT
      明日(#{formatted_date})は雨が降りそうだぞ。
      雨が降ってもジムには行こうな！
      今のところの降水確率はこんな感じだ。
        06〜12時　#{@rainy_percent_06to12}％
        12〜18時　#{@rainy_percent_12to18}％
        18〜24時　#{@rainy_percent_18to24}％
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

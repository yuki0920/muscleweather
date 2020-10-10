class DayAfterTomorrowMessage
  include MessageGenerator

  def initialize(forecast)
    @date_number = DATE_NUMBERS[:day_after_tomorrow]
    @date = Time.current.to_date.next_day(2)
    initialize_forecast(forecast)
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

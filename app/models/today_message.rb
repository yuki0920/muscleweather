class TodayMessage
  include MessageGenerator

  def initialize(forecast)
    @date_number = DATE_NUMBERS[:today]
    @date = Time.current.to_date
    initialize_forecast(forecast)
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
      　06〜12時　#{@rainy_percent_06to12}％
      　12〜18時　#{@rainy_percent_12to18}％
      　18〜24時　#{@rainy_percent_18to24}％
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

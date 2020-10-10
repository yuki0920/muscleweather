module MessageGenerator
  TOKYO_AREA_PATH = 'weatherforecast/pref/area[4]/'
  DATE_NUMBERS = {today: 1, tommorrow: 2, day_after_tomorrow: 3}
  FORECAST_DATA_NUMBERS = {first: 1, second: 2, thrid: 3, fourth: 4}
  MINIMUM_RAINY_PERCENT = 30

  def initialize_forecast(forecast)
    @rainy_percent_06to12, @rainy_percent_12to18, @rainy_percent_18to24 = forecast_datum(forecast)
  end

  def forecast_datum(forecast)
    FORECAST_DATA_NUMBERS.values[1..3].map {|forecast_number| forecast.elements[TOKYO_AREA_PATH + "info[#{@date_number}]/rainfallchance/period[#{forecast_number}]"].text.to_i }
  end

  def generate_message
    rainy? ? rainy_message : sunny_message
  end

  def rainy?
    [@rainy_percent_06to12, @rainy_percent_12to18, @rainy_percent_18to24].any? {|data| data >= MINIMUM_RAINY_PERCENT}
  end

  def formatted_date
    @date.strftime("%m月%d日")
  end
end

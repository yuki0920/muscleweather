class LinebotController < ApplicationController
  require 'line/bot'  # gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'
  require 'time'

  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]

  def callback
    time1 = Time.now
    time2 = time1 + 1.day
    time3 = time1 + 2.days
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    events = client.parse_events_from(body)
    events.each { |event|
      case event
        # メッセージが送信された場合の対応（機能①）
      when Line::Bot::Event::Message
        case event.type
          # ユーザーからテキスト形式のメッセージが送られて来た場合
        when Line::Bot::Event::MessageType::Text
          # event.message['text']：ユーザーから送られたメッセージ
          input = event.message['text']
          url  = "https://www.drk7.jp/weather/xml/13.xml"
          xml  = open( url ).read.toutf8
          doc = REXML::Document.new(xml)
          xpath = 'weatherforecast/pref/area[4]/'
          # 当日朝のメッセージの送信の下限値は20％としているが、明日・明後日雨が降るかどうかの下限値は30％としている
          min_per = 30
          case input
            # 「明日」or「あした」というワードが含まれる場合
          when /.*(明日|あした).*/
            # info[2]：明日の天気
            per06to12 = doc.elements[xpath + 'info[2]/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info[2]/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info[2]/rainfallchance/period[4]'].text
            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              push =
                "明日(#{time2.strftime("%-m月%-d日")})は雨が降りそうだぞ。\n雨が降ってもジムには行こうな！\n今のところの降水確率はこんな感じだ。\n　  6〜12時　#{per06to12}％\n　12〜18時　 #{per12to18}％\n　18〜24時　#{per18to24}％\nまた明日の朝の最新の天気予報で雨が降りそうだったら教えるな！"
            else
              push =
                "明日(#{time2.strftime("%-m月%-d日")})は雨が降らない予定だぞ！\nジムまでランニングで行けるな\nまた明日の朝の最新の天気予報で雨が降りそうだったら教えるぜ！"
            end
          when /.*(明後日|あさって).*/
            per06to12 = doc.elements[xpath + 'info[3]/rainfallchance/period[2]l'].text
            per12to18 = doc.elements[xpath + 'info[3]/rainfallchance/period[3]l'].text
            per18to24 = doc.elements[xpath + 'info[3]/rainfallchance/period[4]l'].text
            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              push =
                "明後日(#{time3.strftime("%-m月%-d日")})は雨が降りそうだ…\nたまには家で自重トレーニングも良いだろうな\n当日の朝に雨が降りそうだったら教えるぞ！"
            else
              push =
                "明後日(#{time3.strftime("%-m月%-d日")})の天気か？\n気が早いな！\n明後日は雨が降らない予定だぞ\nまた当日の朝の最新の天気予報で雨が降りそうだったら教えるからな！"
            end
          when /.*(素敵|ステキ|すてき|面白い|おもしろい|ありがと|すごい|スゴイ|スゴい|好き|頑張|がんば|ガンバ|筋肉| バルク|プロテイン|ジム|アミノ酸|マッチョ|格好|カッコ良い|たくましい|逞|イケメン).*/
            push =
              "ありがとな！\nちょっと、嬉しいじゃねえか..."
          when /.*(こんにちは|こんばんは|初めまして|はじめまして|おはよう).*/
            push =
              "よう、元気か？\n声をかけてくれてありがとな\n今日もしっかりジムに行って汗を流そうぜ！"
          else
            per06to12 = doc.elements[xpath + 'info/rainfallchance/period[2]l'].text
            per12to18 = doc.elements[xpath + 'info/rainfallchance/period[3]l'].text
            per18to24 = doc.elements[xpath + 'info/rainfallchance/period[4]l'].text
            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              word =
                ["雨だけど元気出していこうな！",
                 "雨に負けずテストステロン全開で行こうぜ！！！",
                 "雨だけどジムにはしっかり行こうな！"].sample
              push =
                "今日(#{time1.strftime("%-m月%-d日")})の天気？\n雨が降りそうだから傘とサラダチキン持って行けよ！\n　  6〜12時　#{per06to12}％\n　12〜18時　 #{per12to18}％\n　18〜24時　#{per18to24}％\n#{word}"
            else
              word =
                ["ジムまでランニングで行けるな！",
                 "たまには日焼けも良いかもな！",
                 "筋トレしてバルクアップ目指そうぜ！",
                 "雨が降ったらごめんな！"].sample
              push =
                "今日(#{time1.strftime("%-m月%-d日")})の天気？\n雨は降らなさそうだよ。\n#{word}"
            end
          end
          # テキスト以外（画像等）のメッセージが送られた場合
        else
          push = "テキスト以外は解せぬ"
        end
        message = {
          type: 'text',
          text: push
        }
        client.reply_message(event['replyToken'], message)
        # LINEお友達追された場合（機能②）
      when Line::Bot::Event::Follow
        # 登録したユーザーのidをユーザーテーブルに格納
        line_id = event['source']['userId']
        User.create(line_id: line_id)
        # LINEお友達解除された場合（機能③）
      when Line::Bot::Event::Unfollow
        # お友達解除したユーザーのデータをユーザーテーブルから削除
        line_id = event['source']['userId']
        User.find_by(line_id: line_id).destroy
      end
    }
    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end
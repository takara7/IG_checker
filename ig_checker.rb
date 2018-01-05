#!/usr/bin/env ruby

require 'yaml'
require_relative 'instagram_checker'
require 'twitter'
require_relative 'twitter_media_patch'
using TwitterMediaPatch

TWITTER_TEXT_LIMIT = 140
TWITTER_URL_LENGTH = 23

def log(*message, out: $stderr)
  time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
  message.each {|m| out.puts "[#{time}] #{m}"}
end

config = YAML.load_file("config.yaml")
twitter = Twitter::REST::Client.new do |client|
  client.consumer_key = config["consumer_key"]
  client.consumer_secret = config["consumer_secret"]
  client.access_token = config["access_token"]
  client.access_token_secret = config["access_token_secret"]
end
users = config["users"]

time_file = File.expand_path("last_check.tsv", __dir__)
last_check = {}
if File.exist?(time_file)
  File.open(time_file) {|f|
    f.each do |line|
      id, time = line.split
      last_check[id] = Time.at(time.to_i)
    end
  }
else
  users.each do |user|
    last_check[user["id"]] = Time.now
  end
end

users.each do |user|
  id, name = user["id"], user["name"]
  begin
    checker = InstagramChecker.new(id, last_check[id]) do |entry|
      text = entry.caption
      url = entry.url
      tweet = nil

      case entry.type
      when "GraphImage"
        media_count = "（画像1枚）"
      when "GraphVideo"
        media_count = "（動画1個）"
      when "GraphSidecar"
        video = entry.media.count(&:video?)
        image = entry.media.size - video
        ary = []
        ary << "画像#{image}枚" if image > 0
        ary << "動画#{video}個" if video > 0
        media_count = "（#{ary.join('、')}）"
      end

      if name
        length = name.size + media_count.size + text.size + TWITTER_URL_LENGTH + 2
        if length > 140
          limit = TWITTER_TEXT_LIMIT - TWITTER_URL_LENGTH - 3 -
                  name.size - media_count.size
          text = text[0, limit] + "…"
        end
        tweet = "#{name}#{media_count}：#{text}\n#{url}"
      else
        length = media_count.size + text.size + TWITTER_URL_LENGTH + 1
        if length > 140
          limit = TWITTER_TEXT_LIMIT - TWITTER_URL_LENGTH - 2
          text = text[0, limit] + "…"
        end
        tweet = "#{text}#{media_count}\n#{url}"
      end

      media = entry.media.take(4).map do |m|
        url = entry.type == "GraphVideo" ? m.video_url : m.image_url
        twitter.upload(open(url))
      end

      twitter.update(tweet, media_ids: media.join(","))
      log("Successfully tweeted the update of #{id}", out: $stdout)
      last_check[id] = entry.time
    end
    checker.check
  rescue => e
    log("#{e.class}: #{e.message} for #{id}\n\t#{e.backtrace.join("\n\t")}")
  end
end

File.open(time_file, "w") do |f|
  f.puts last_check.map {|id, time| "#{id}\t#{time.to_i}"}
end

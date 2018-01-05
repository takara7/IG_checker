require 'open-uri'
require 'json'

module Instagram
  DOMAIN = "https://www.instagram.com"

  def self.get_json(path)
    path = "#{DOMAIN}/#{path}" unless path.start_with?("http")
    html = open(path).read
    json = html.slice(/window\._sharedData = ({.+});<\/script>/, 1)
    JSON.parse(json)
  end

  class User
    attr_reader :entries

    def initialize(user_id)
      @user_id = user_id.dup.freeze
      @entries = []
      load(@user_id)
      @entries.freeze
    end

    def load(user_id)
      data = Instagram.get_json("#{DOMAIN}/#{user_id}/")
      data["entry_data"]["ProfilePage"][0]["user"]["media"]["nodes"].each do |i|
        @entries << Entry.new(i)
      end
    end
  end

  class Entry
    attr_reader :id, :time, :caption, :url, :type, :media

    def initialize(hash)
      parse(hash)
    end

    private
    def parse(hash)
      @id = hash["id"]
      @is_video = hash["is_video"]
      @time = Time.at(hash["date"])
      @caption = hash["caption"]
      @url = "#{DOMAIN}/p/#{hash['code']}/"
      @type = hash["__typename"]

      if @type == "GraphImage"
        hash["display_url"] = hash["display_src"]
        @media = [Media.new(hash)]
      else
        get_detail
      end
    end

    def get_detail
      json = Instagram.get_json(@url)
      detail = json["entry_data"]["PostPage"][0]["graphql"]["shortcode_media"]

      if detail.has_key?("edge_sidecar_to_children")
        edges = detail["edge_sidecar_to_children"]["edges"]
        @media = edges.map {|i| Media.new(i["node"])}
      elsif detail.has_key?("video_url")
        @media = [Media.new(detail)]
      end
    end
  end

  class Media
    attr_reader :is_video, :image_url, :video_url, :type
    alias video? is_video

    def initialize(hash)
      parse(hash)
    end

    private def parse(hash)
      @is_video = hash["is_video"]
      @image_url = hash["display_url"]
      @video_url = hash["video_url"]
      @type = hash["__typename"]
    end
  end
end

class InstagramChecker
  attr_reader :user_id, :last_check

  def initialize(user_id, last_check = Time.now, &block)
    raise ArgumentError unless block_given?
    @user_id = user_id
    @block = block
    @last_check = last_check
  end

  def check
    instagram = Instagram::User.new(@user_id)
    new = instagram.entries.take_while {|i| i.time > @last_check}
    @last_check = Time.now
    new.each do |i|
      updated(i)
    end
  end

  def updated(entry)
    @block.call(entry)
  end
end

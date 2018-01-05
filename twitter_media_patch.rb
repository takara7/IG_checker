require 'twitter'
require 'base64'

module TwitterMediaPatch
  refine Twitter::REST::Media do
    def upload(media)
      if mp4?(media)
        upload_video(media)
      else
        super(media)
      end
    end

    def upload_video(media)
      raise(Twitter::Error::UnacceptableIO.new) unless media.respond_to?(:to_io)
      init = request(:post,
                     command: 'INIT',
                     media_type: 'video/mp4',
                     total_bytes: media.size,
                     media_category: 'tweet_video')
      media_id = init[:media_id]

      until media.eof?
        chunk_size = 5_000_000
        chunk = media.read(chunk_size)
        seg ||= -1
        request(:post,
                command: 'APPEND',
                media_id: media_id,
                segment_index: seg += 1,
                key: :media,
                media: Base64.encode64(chunk))
      end
      media.close

      info = request(:post, command: 'FINALIZE', media_id: media_id)

      while %w(pending in_progress).include?(info[:processing_info][:state])
        sleep info[:processing_info][:check_after_secs]
        info = request(:get, command: 'STATUS', media_id: media_id)
      end

      init[:media_id]
    end

    private

    def mp4?(media)
      magic_number = "\0\0\0 ftypisom\0\0\2\0"
      header = media.read(16)
      media.rewind

      header == magic_number
    end

    def request(method, options)
      base_url = 'https://upload.twitter.com'
      path = '/1.1/media/upload.json'
      conn = connection.dup
      conn.url_prefix = base_url
      headers = Twitter::Headers.new(self, method, base_url + path, options).request_headers
      conn.send(method, path, options) {|request| request.headers.update(headers)}.env.body
    end
  end
end

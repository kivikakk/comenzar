# frozen_string_literal: true

require "erb"

class Assets
  def initialize(root)
    @store = {}
    root.glob("*").each do |path|
      @store[path.basename.to_s] = Asset.new(
        body: path.read,
        content_type: content_type_for(path.extname),
      )
    end
  end

  def for(path)
    @store[path]
  end

  private

  def content_type_for(extname)
    case extname
    when ".html"
      Views::ContentType::HTML
    when ".css"
      Views::ContentType::CSS
    when ".gif"
      Views::ContentType::GIF
    when ".png"
      Views::ContentType::PNG
    else
      raise "Unknown content type for #{extname}"
    end
  end

  class Asset
    def initialize(body:, content_type:)
      @body = body
      @content_type = content_type
    end

    attr_reader :body, :content_type
  end
end

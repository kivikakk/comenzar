# frozen_string_literal: true
# typed: strict

require "erb"

class Assets
  extend T::Sig

  sig {params(root: Pathname).void}
  def initialize(root)
    @store = T.let({}, T::Hash[String, Asset])
    root.glob("*").each do |path|
      @store[path.basename.to_s] = Asset.new(
        body: path.read,
        content_type: content_type_for(path.extname),
      )
    end
  end

  sig {params(path: String).returns(T.nilable(Asset))}
  def for(path)
    @store[path]
  end

  private

  sig {params(extname: String).returns(Views::ContentType)}
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

  class Asset < T::Struct
    const :body, String
    const :content_type, Views::ContentType
  end
end

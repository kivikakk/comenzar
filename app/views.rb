# frozen_string_literal: true

require "erb"

class Views
  class ContentType
    def initialize(mime)
      @mime = mime
    end

    def serialize
      @mime
    end

    HTML = new("text/html")
    CSS = new("text/css")
    PNG = new("image/png")
    GIF = new("image/gif")
  end

  def initialize(root)
    @holder = Class.new.new
    @rendered = {}

    @layout = parse(root.join("layout.html.erb"), "layout")
    @home = parse(root.join("home.html.erb"), "home(q, message)")
    @explainer = parse(root.join("_explainer.html.erb"), "explainer").call
  end

  def home(q: nil, message: nil)
    if !q && !message
      @home_nil ||= @layout.call { @home.call(nil, nil) }
    else
      @layout.call { @home.call(q, message) }
    end
  end

  attr_reader :explainer

  private

  def parse(path, proto)
    fname = ERB.new(path.read).def_method(@holder.class, proto, path.to_s)
    @holder.method(fname)
  end
end

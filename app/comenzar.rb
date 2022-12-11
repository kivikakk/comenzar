# frozen_string_literal: true
# typed: strict

require "uri"
require "cgi"

require_relative "views"

GOOGLE_SEARCH = "https://google.com/search?hl=en"
GOOGLE_IMAGE_SEARCH = "https://google.com/search?hl=en&tbm=isch"
DUCKDUCKGO_SEARCH = "https://duckduckgo.com/"

CHEWWO = /\A[^a-z0-9]*(hi|hello|hey|heya|chewwo|yawonk|hola|howdy)[^a-z0-9]*\z/i

class Comenzar < Hanami::API
  get "/" do
    headers["Referrer-Policy"] = "no-referrer"
    q = params[:q]

    next ok(views.home) if !q || q.strip.empty?
    next ok(views.home(q:, message: "Chewwo!")) if q =~ CHEWWO

    if q.sub!(/(\A|\s)i:/i, "")
      next add_qsp(GOOGLE_IMAGE_SEARCH, q:)
    end

    if q.sub!(/\A(\w+):/i, "")
      next add_qsp(DUCKDUCKGO_SEARCH, q: "!#$1 #{q}")
    end

    next add_qsp(GOOGLE_SEARCH, q:)
  end

  get "/comenzar.css" do
    [200, {"Content-Type" => "text/css"}, views.css]
  end

  class ContentType < T::Enum
    enums do
      HTML = new("text/html")
      CSS = new("text/css")
    end
  end

  module Heppers
    extend T::Sig, T::Generic
    requires_ancestor {BlockContext}

    sig {params(body: String, ct: ContentType).returns(T.untyped)}
    def ok(body, ct: ContentType::HTML)
      [200, {"Content-Type" => ct.to_s}, body]
    end

    sig {params(url: String, params: String).returns(T.untyped)}
    def add_qsp(url, **params)
      uri = URI.parse(url)
      query = CGI.parse(uri.query || "")
      query.merge!(params)
      uri.query = URI.encode_www_form(query)
      redirect uri.to_s, 302
    end

    sig {returns(Views)}
    def views
      @views ||= T.let(Views.new(Pathname.new(__dir__).join("..", "views")), T.nilable(Views))
    end
  end

  helpers(Heppers)
end

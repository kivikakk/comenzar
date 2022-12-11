# frozen_string_literal: true
# typed: strict

require "uri"
require "cgi"

require_relative "views"

GOOGLE_SEARCH = "https://google.com/search?hl=en"
GOOGLE_IMAGE_SEARCH = "https://google.com/search?hl=en&tbm=isch"
DUCKDUCKGO_SEARCH = "https://duckduckgo.com/"

CHEWWO = /\A[^a-z0-9]*(hi|hello|hey|heya|chewwo|yawonk|hola|howdy)[^a-z0-9]*\z/i

STATICS = T.let({
  "adc" => "https://adc.hrzn.ee",
  "ing" => "https://www.ing.com.au/securebanking/",
  "28d" => "https://servicecentre.latitudefinancial.com.au/login",
}, T::Hash[String, String])

STATIC_MATCH = T.let(Regexp.union(STATICS.keys.map {|k| /\A#{k}\z/i }), Regexp)

class Comenzar < Hanami::API
  get "/" do
    headers["Referrer-Policy"] = "no-referrer"
    headers["X-Robots-Tag"] = "noindex"

    q = params[:q]&.strip || ""

    next ok(views.home) if q.empty?
    next ok(views.home(q:, message: "Chewwo!!!! <span class='bunnywave'></span>")) if q =~ CHEWWO
    next redirect(STATICS[q]) if q =~ STATIC_MATCH

    if q.sub!(/(\A|\s)i:/i, "")
      next add_qsp(GOOGLE_IMAGE_SEARCH, q:)
    end

    if q.sub!(/\A(\w+):/i, "")
      next add_qsp(DUCKDUCKGO_SEARCH, q: "!#$1 #{q}")
    end

    next add_qsp(GOOGLE_SEARCH, q:)
  end

  get "/comenzar.css" do
    ok(views.css, ct: ContentType::CSS)
  end

  get "/bunnywave.png" do
    ok(views.bunnywave, ct: ContentType::PNG)
  end

  class ContentType < T::Enum
    enums do
      HTML = new("text/html")
      CSS = new("text/css")
      PNG = new("image/png")
    end
  end

  module Heppers
    extend T::Sig, T::Generic
    requires_ancestor {BlockContext}

    sig {params(body: String, ct: ContentType).returns(T.untyped)}
    def ok(body, ct: ContentType::HTML)
      [200, {"Content-Type" => ct.serialize}, body]
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

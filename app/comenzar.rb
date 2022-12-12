# frozen_string_literal: true
# typed: strict

require "uri"
require "cgi"

require_relative "views"
require_relative "assets"
require_relative "spider"

SPIDER = T.let(spider do
  free(:i).qsp("https://google.com/search?hl=en&tbm=isch", :q)
  free(:sw).replace("https://en.wiktionary.org/wiki/{query}#Spanish", space: "_")
  free(:auslan).replace("https://find.auslan.fyi/search?query={query}")
  free(:enes).replace("https://translate.google.com/?source=osdd&sl=en&tl=es&text={query}&op=translate")
  free(:esen).replace("https://translate.google.com/?source=osdd&sl=es&tl=en&text={query}&op=translate")
end, Spider)

GOOGLE_SEARCH = "https://google.com/search?hl=en"
DUCKDUCKGO_SEARCH = "https://duckduckgo.com/"
CHEWWO = /\A[^a-z0-9]*(hi|hello|hey|heya|chewwo|yawonk|hola|howdy)[^a-z0-9]*\z/i

STATICS = T.let({
  "adc" => "https://adc.hrzn.ee",
  "ynab" => "https://app.youneedabudget.com/",
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
    next redirect(STATICS[q], 302) if q =~ STATIC_MATCH
    if out = SPIDER.(q)
      next redirect(out, 302)
    end

    if q.sub!(/\A(\w+):/i, "")
      next add_qsp(DUCKDUCKGO_SEARCH, q: "!#$1 #{q}")
    end

    q.sub!(/(\A|\s)(!g|g!)(\z|\s)/i, "")

    next add_qsp(GOOGLE_SEARCH, q:)
  end

  get "/assets/:path" do |path|
    asset = assets.for(T.must(params[:path])) \
      or next status 404
    ok(asset.body, ct: asset.content_type)
  end

  module Heppers
    extend T::Sig, T::Generic
    requires_ancestor {BlockContext}

    sig {params(body: String, ct: Views::ContentType).returns(T.untyped)}
    def ok(body, ct: Views::ContentType::HTML)
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

    sig {returns(Assets)}
    def assets
      @assets ||= T.let(Assets.new(Pathname.new(__dir__).join("..", "assets")), T.nilable(Assets))
    end
  end

  helpers(Heppers)
end

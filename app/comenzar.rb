# frozen_string_literal: true
# typed: strict

require "uri"
require "cgi"

require_relative "views"
require_relative "assets"
require_relative "spider"
require_relative "../web"

GOOGLE_SEARCH = "https://google.com/search?hl=en"
DUCKDUCKGO_SEARCH = "https://duckduckgo.com/"

class Comenzar < Hanami::API
  get "/" do
    headers["Referrer-Policy"] = "no-referrer"
    headers["X-Robots-Tag"] = "noindex"

    q = params[:q]&.strip || ""

    next ok(views.home) if q.empty?

    case SPIDER.(q)
    in redirect: url
      next redirect(url, 302)
    in message:
      next ok(views.home(q:, message:))
    in NilClass
      # pass
    else
      raise NotImplementedError, "unhandled spider response"
    end

    if q.sub!(/\A(\w+):(?!:)/i, "")
      next add_qsp(DUCKDUCKGO_SEARCH, q: "!#$1 #{q}")
    end

    q.sub!(/(\A|\s)(!g|g!)(\z|\s)/i, "")

    add_qsp(GOOGLE_SEARCH, q:)
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

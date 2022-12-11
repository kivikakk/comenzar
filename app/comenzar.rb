# frozen_string_literal: true
# typed: strict

require "uri"
require "cgi"

GOOGLE_SEARCH = "https://google.com/search?hl=en"
GOOGLE_IMAGE_SEARCH = "https://google.com/search?hl=en&tbm=isch"

class Comenzar < Hanami::API
  extend T::Sig

  get "/" do
    headers["Referrer-Policy"] = "no-referrer"
    q = params[:q]
    next redirect "/nyonk", 302 if !q

    if q.sub!(/(\A|\s)i:/i, '')
      next add_qsp(GOOGLE_IMAGE_SEARCH, q:)
    end

    next add_qsp(GOOGLE_SEARCH, q:)
  end

  module Qsp
    extend T::Sig, T::Generic
    requires_ancestor {BlockContext}

    sig {params(url: String, params: String).returns(T.untyped)}
    def add_qsp(url, **params)
      uri = URI.parse(url)
      query = CGI.parse(uri.query || "")
      query.merge!(params)
      uri.query = URI.encode_www_form(query)
      redirect uri.to_s, 302
    end
  end

  helpers(Qsp)
end

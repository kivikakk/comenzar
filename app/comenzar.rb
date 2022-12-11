# frozen_string_literal: true
# typed: strict

require "uri"
require "cgi"

GOOGLE_SEARCH = "https://google.com/search?hl=en"
GOOGLE_IMAGE_SEARCH = "https://google.com/search?hl=en&tbm=isch"
DUCKDUCKGO_SEARCH = "https://duckduckgo.com/"

class Comenzar < Hanami::API
  extend T::Sig

  get "/" do
    headers["Referrer-Policy"] = "no-referrer"
    q = params[:q]
    next home if !q

    if q.sub!(/(\A|\s)i:/i, "")
      next add_qsp(GOOGLE_IMAGE_SEARCH, q:)
    end

    if q.sub!(/(\A|\s)ddg:/i, "")
      next add_qsp(DUCKDUCKGO_SEARCH, q:)
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


    sig {returns(T.untyped)}
    def home
      [200, {"Content-Type" => "text/html"}, <<~HTML]
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>Comenzar</title>
          <style>
            /* Styles the home page in soft greens, whites, light shadows — elegant and natural. */
            body {
              background-color: #f0f0f0;
              background-image: linear-gradient(to bottom, #f0f0f0, #f0f0f0);
              background-repeat: repeat-x;
              font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
              font-size: 14px;
              line-height: 20px;
              color: #333333;
            }
            h1 {
              color: #333333;
              font-size: 36px;
              font-weight: 300;
              line-height: 36px;
              margin: 0 0 18px;
              text-shadow: 0 1px 0 #ffffff;
            }
            form {
              margin: 18px 0;
            }
            input[type="text"] {
              background-color: #ffffff;
              background-image: linear-gradient(to bottom, #ffffff, #ffffff);
              background-repeat: repeat-x;
              border: 1px solid #cccccc;
              border-radius: 4px;
              box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.075);
              color: #555555;
              display: inline-block;
              font-size: 14px;
              height: 20px;
              line-height: 20px;
              margin-bottom: 0;
              padding: 4px 6px;
              transition: border linear 0.2s, box-shadow linear 0.2s;
              vertical-align: middle;
            }
            input[type="text"]:focus {
              border-color: rgba(82, 168, 236, 0.8);
              outline: 0;
              box-shadow: 0 0 8px rgba(82, 168, 236, 0.6);
            }
            input[type="submit"] {
              background-color: #ffffff;
              background-image: linear-gradient(to bottom, #ffffff, #ffffff);
              background-repeat: repeat-x;
              border: 1px solid #cccccc;
              border-radius: 4px;
              box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.2), 0 1px 2px rgba(0, 0, 0, 0.05);
              color: #333333;
              cursor: pointer;
              display: inline-block;
              font-size: 14px;
              font-weight: 400;
              line-height: 20px;
              margin-bottom: 0;
              padding: 4px 12px;
              text-align: center;
              vertical-align: middle;
              white-space: nowrap;
            }
            input[type="submit"]:hover,
            input[type="submit"]:focus {
              background-color: #e6e6e6;
              background-position: 0 -15px;
              border-color: #adadad;
              color: #333333;
              text-decoration: none;
            }
            input[type="submit"]:active {
              background-color: #cccccc;
              background-image: none;
              border-color: #999999;
              box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.15);
              outline: 0;
              outline: thin dotted \9;
              /* IE6-9 */
            }
            input[type="submit"][disabled],
            input[type="submit"][disabled]:hover,
            input[type="submit"][disabled]:focus,
            input[type="submit"][disabled]:active {
              background-color: #e6e6e6;
              background-image: none;
              border-color: #adadad;
              box-shadow: none;
              cursor: default;
              opacity: 0.65;
              filter: alpha(opacity=65);
            }
            input:-moz-placeholder {
              color: #999999;
            }
            input::-webkit-input-placeholder {
              color: #999999;
            }

          </style>
        </head>
        <body>
          <h1>Comenzar</h1>
          <form action="/" method="get">
            <input type="text" name="q" placeholder="Query" autofocus>
            <input type="submit" value="Search">
          </form>
        </body>
        </html>
      HTML
    end
  end

  helpers(Qsp)
end

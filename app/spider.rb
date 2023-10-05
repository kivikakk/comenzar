# frozen_string_literal: true

def spider(&blk)
  dsl = Spider::DSL.new
  dsl.instance_eval(&blk)
  dsl.resolve!
end

class Spider
  class DSL
    def initialize
      @matchers = {}
    end

    def free(token)
      raise "token #{token} already defined" if @matchers[token]
      @matchers[token] = Free.new(token)
    end

    def static(*tokens)
      matcher = Static.new(tokens)
      tokens.each do |token|
        raise "token #{token} already defined" if @matchers[token]
        @matchers[token] = matcher
      end
      matcher
    end

    def resolve!
      raise "all matchers must be valid" unless @matchers.values.all?(&:valid?)
      Spider.new(@matchers.values)
    end

    class Matcher
      def valid?; end
      def match(q); end
    end

    class Free < Matcher
      def initialize(token)
        @regexp = /(\A|\s)#{token}:/i
        @rewriter = nil
      end

      def valid?
        @rewriter != nil
      end

      def match(q)
        if rem = q.dup.sub!(@regexp, "")
          @rewriter.rewrite(rem)
        end
      end

      def qsp(url, param)
        @rewriter = Qsp.new(url:, param:)
      end

      def replace(url, space: "%20")
        @rewriter = Replace.new(url:, space:)
      end
    end

    class Static < Matcher
      def initialize(tokens)
        @regexp = Regexp.union(tokens.map {|token| /\A#{token}\z/i})
        @response = nil
      end

      def valid?
        @response != nil
      end

      def match(q)
        if q =~ @regexp
          @response
        end
      end

      def redirect(url)
        @response = { redirect: url }
      end

      def message(message)
        @response = { message: }
      end
    end

    class Rewriter
      def rewrite(q); end
    end

    class Qsp < Rewriter
      def initialize(url:, param:)
        @url = url
        @param = param
      end

      def rewrite(q)
        uri = URI.parse(@url)
        query = CGI.parse(uri.query || "")
        query.merge!(@param => q)
        uri.query = URI.encode_www_form(query)  
        { redirect: uri.to_s }
      end
    end

    class Replace < Rewriter
      def initialize(url:, space:)
        @url = url
        @space = space
      end

      def rewrite(q)
        { redirect: @url.sub("{query}", q.gsub(" ", @space)) }
      end
    end
  end

  def initialize(matchers)
    @matchers = matchers
  end

  def call(q)
    @matchers.find do |matcher|
      if result = matcher.match(q)
        return result
      end
    end
    nil
  end
end

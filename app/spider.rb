# frozen_string_literal: true
# typed: strict

extend T::Sig

sig do
  params(
    blk: T.proc.bind(Spider::DSL).void
  )
  .returns(Spider)
end
def spider(&blk)
  dsl = Spider::DSL.new
  dsl.instance_eval(&blk)
  dsl.resolve!
end

class Spider
  extend T::Sig

  Response = T.type_alias { T.any(
    { redirect: String },
    { message: String },
  ) }

  class DSL
    extend T::Sig

    sig {void}
    def initialize
      @matchers = T.let({}, T::Hash[Symbol, Matcher])
    end

    sig {params(token: Symbol).returns(Free)}
    def free(token)
      raise "token #{token} already defined" if @matchers[token]
      @matchers[token] = Free.new(token)
    end

    sig {params(tokens: Symbol).returns(Static)}
    def static(*tokens)
      matcher = Static.new(tokens)
      tokens.each do |token|
        raise "token #{token} already defined" if @matchers[token]
        @matchers[token] = matcher
      end
      matcher
    end

    sig {returns(Spider)}
    def resolve!
      raise "all matchers must be valid" unless @matchers.values.all?(&:valid?)
      Spider.new(@matchers.values)
    end

    class Matcher
      extend T::Sig, T::Helpers
      abstract!

      sig {abstract.returns(T::Boolean)}
      def valid?; end

      sig {abstract.params(q: String).returns(T.nilable(Response))}
      def match(q); end
    end

    class Free < Matcher
      extend T::Sig

      sig {params(token: Symbol).void}
      def initialize(token)
        @regexp = T.let(/(\A|\s)#{token}:/i, Regexp)
        @rewriter = T.let(nil, T.nilable(Rewriter))
      end

      sig {override.returns(T::Boolean)}
      def valid?
        @rewriter != nil
      end

      sig {override.params(q: String).returns(T.nilable(Response))}
      def match(q)
        if rem = q.dup.sub!(@regexp, "")
          T.must(@rewriter).rewrite(rem)
        end
      end

      sig {params(url: String, param: Symbol).void}
      def qsp(url, param)
        @rewriter = Qsp.new(url:, param:)
      end

      sig {params(url: String, space: String).void}
      def replace(url, space: "%20")
        @rewriter = Replace.new(url:, space:)
      end
    end

    class Static < Matcher
      extend T::Sig

      sig {params(tokens: T::Array[Symbol]).void}
      def initialize(tokens)
        @regexp = T.let(Regexp.union(tokens.map {|token| /\A#{token}\z/i}), Regexp)
        @response = T.let(nil, T.nilable(Response))
      end

      sig {override.returns(T::Boolean)}
      def valid?
        @response != nil
      end

      sig {override.params(q: String).returns(T.nilable(Response))}
      def match(q)
        if q =~ @regexp
          @response
        end
      end

      sig {params(url: String).void}
      def redirect(url)
        @response = { redirect: url }
      end

      sig {params(message: String).void}
      def message(message)
        @response = { message: }
      end
    end

    class Rewriter
      extend T::Sig, T::Helpers
      abstract!

      sig {abstract.params(q: String).returns(Response)}
      def rewrite(q); end
    end

    class Qsp < Rewriter
      extend T::Sig

      sig {params(url: String, param: Symbol).void}
      def initialize(url:, param:)
        @url = url
        @param = param
      end

      sig {override.params(q: String).returns(Response)}
      def rewrite(q)
        uri = URI.parse(@url)
        query = CGI.parse(uri.query || "")
        query.merge!(@param => q)
        uri.query = URI.encode_www_form(query)  
        { redirect: uri.to_s }
      end
    end

    class Replace < Rewriter
      extend T::Sig

      sig {params(url: String, space: String).void}
      def initialize(url:, space:)
        @url = url
        @space = space
      end

      sig {override.params(q: String).returns(Response)}
      def rewrite(q)
        { redirect: @url.sub("{query}", q.gsub(" ", @space)) }
      end
    end
  end

  sig {params(matchers: T::Array[DSL::Matcher]).void}
  def initialize(matchers)
    @matchers = matchers
  end

  sig {params(q: String).returns(T.nilable(Response))}
  def call(q)
    @matchers.find do |matcher|
      if result = matcher.match(q)
        return result
      end
    end
    nil
  end
end

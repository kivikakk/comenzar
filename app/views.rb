# frozen_string_literal: true
# typed: strict

require "erb"

class Views
  extend T::Sig

  sig {params(root: Pathname).void}
  def initialize(root)
    @holder = T.let(Class.new.new, Object)
    @rendered = T.let({}, T::Hash[Symbol, String])

    @layout = T.let(parse(root.join("layout.html.erb"), "layout(content)"), T.untyped)
    @home = T.let(parse(root.join("home.html.erb"), "home(q, message)"), T.untyped)
    @css = T.let(root.join("comenzar.css").read, String)
  end

  sig {params(q: T.nilable(String), message: T.nilable(String)).returns(String)}
  def home(q: nil, message: nil)
    if !q && !message
      @home_nil ||= T.let(T.let(@layout.call(@home.call(nil, nil)), String), T.nilable(String))
    else
      @layout.call(@home.call(q, message))
    end
  end

  sig {returns(String)}
  attr_reader :css

  private

  sig {params(path: Pathname, proto: String).returns(T.untyped)}
  def parse(path, proto)
    fname = T.unsafe(ERB.new(path.read)).def_method(@holder.class, proto, path.to_s)
    @holder.method(fname)
  end
end

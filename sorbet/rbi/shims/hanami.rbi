# frozen_string_literal: true
# typed: strict

class ::Hanami::Router::Block::Context
  sig {params(value: T.nilable(T::Hash[::String, ::String])).returns(T::Hash[::String, ::String])}
  def headers(value=nil); end

  sig {returns(T::Hash[::Symbol, ::String])}
  def params; end
end

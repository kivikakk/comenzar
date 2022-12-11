# frozen_string_literal: true
# typed: true

require "bundler/setup"
require "hanami/api"
require "sorbet-runtime"

require_relative "../app/comenzar"

# HACK: Tapioca.
class Rails
  def self.application
    self
  end

  def self.config
    self
  end
end

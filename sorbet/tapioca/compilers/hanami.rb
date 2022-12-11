# typed: strict
# frozen_string_literal: true

require "hanami/api"

class Tapioca::Dsl::Compilers::Hanami < Tapioca::Dsl::Compiler
  extend T::Sig

  ConstantType = type_member {{ upper: T.class_of(::Hanami::API) }}

  sig {override.returns(T::Enumerable[Module])}
  def self.gather_constants
    all_classes.select { |c| c < ::Hanami::API}
  end

  sig {override.void}
  def decorate
    root.create_path(constant) do |klass|
      # All a big hack.  Do better without so many private methods.
      create_method_from_def(klass, constant.method(:get))
      method = T.cast(klass.nodes.last, ::RBI::Method)
      method.is_singleton = true
      sig = T.must(method.sigs.first)
      block_arg = T.must(sig.params.last)
      block_arg.send(:instance_variable_set, :@type, "T.proc.bind(::#{constant.name}::BlockContext).returns(T.untyped)")
      
      klass.create_class("BlockContext", superclass_name: "::Hanami::API::Block::Context") do |blockcontext|
        T.let(constant.const_get(:BlockContext), Class).included_modules.each do |included|
          name = "::#{T.must(included.name)}"
          next unless name.start_with?("::#{constant.name}::")
          blockcontext.create_include(name)
        end
      end
    end
  end
end

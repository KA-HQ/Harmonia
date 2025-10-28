# frozen_string_literal: true

require 'trophonius'

module Harmonia
  class Error < StandardError; end
end

require 'harmonia/railtie' if defined?(Rails)

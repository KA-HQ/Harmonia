# frozen_string_literal: true

module Harmonia
  class Railtie < Rails::Railtie
    generators do
      require 'generators/harmonia/install_generator'
      require 'generators/harmonia/sync_generator'
    end
  end
end

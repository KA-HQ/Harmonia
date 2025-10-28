# frozen_string_literal: true

class DatabaseConnector
  attr_accessor :hostname

  def open_database(&block)
    raise ArgumentError, 'No hostname set' if @hostname.blank?
    raise ArgumentError, 'No block given' if block.blank?

    connect
    yield block
  ensure
    disconnect
  end

  private

  def connect
    Trophonius.configure do |config|
      config.host = @hostname
      config.database = 'Alloqate'
      config.username = Rails.application.credentials.dig(:filemaker, :username)
      config.password = Rails.application.credentials.dig(:filemaker, :password)
      config.ssl = true # or false depending on whether https or http should be used
      config.debug = true # will output more information when true
      config.pool_size = ENV.fetch('trophonius_pool', 5) # use multiple data api connections with a loadbalancer to improve performance
    end
    @connection_manager = Trophonius.connection_manager
  end

  def disconnect
    @connection_manager.disconnect_all
  end
end

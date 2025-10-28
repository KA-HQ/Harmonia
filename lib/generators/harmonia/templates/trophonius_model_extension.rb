# frozen_string_literal: true

module Trophonius
  class Model
    # Converts a Trophonius record to PostgreSQL-compatible attributes
    # @param record [Trophonius::Record] The Trophonius record instance to convert
    def self.to_pg(record)
      raise StandardError, 'Implement to_pg'
    end
  end
end

# frozen_string_literal: true

module Harmonia
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def copy_database_connector
        copy_file "database_connector.rb", "app/services/database_connector.rb"
      end

      def copy_trophonius_extension
        copy_file "trophonius_model_extension.rb", "config/initializers/trophonius_model_extension.rb"
      end

      def copy_sync_model
        copy_file "harmonia_sync.rb", "app/models/harmonia/sync.rb"
      end

      def generate_migration
        migration_template "create_harmonia_syncs.rb", "db/migrate/create_harmonia_syncs.rb"
      end

      def show_readme
        puts "Replace all instances of YourTrophoniusModel with the name of your model" if behavior == :invoke
      end

      # Required for migration_template to work
      def self.next_migration_number(dirname)
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end
    end
  end
end

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

      def copy_application_record_extension
        copy_file "application_record_extension.rb", "app/models/application_record.rb"
      end

      def copy_sync_model
        copy_file "harmonia_sync.rb", "app/models/harmonia/sync.rb"
      end

      def generate_migration
        migration_template "create_harmonia_syncs.rb", "db/migrate/create_harmonia_syncs.rb"
      end

      def show_readme
        readme_content = <<~README

          ========================================
          Harmonia has been installed!
          ========================================

          Files created:
          - app/services/database_connector.rb
          - config/initializers/trophonius_model_extension.rb
          - app/models/application_record.rb (with to_fm extension)
          - app/models/harmonia/sync.rb
          - db/migrate/..._create_harmonia_syncs.rb

          Next steps:
          1. Run migrations: rails db:migrate
          2. Update database_connector.rb with your FileMaker database name
          3. Add FileMaker credentials to Rails credentials
          4. Replace all instances of YourTrophoniusModel with your actual model names
          5. Generate syncers:
             - rails generate harmonia:sync ModelName (FileMaker -> ActiveRecord)
             - rails generate harmonia:reverse_sync ModelName (ActiveRecord -> FileMaker)

        README

        say readme_content, :green if behavior == :invoke
      end

      # Required for migration_template to work
      def self.next_migration_number(dirname)
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end
    end
  end
end

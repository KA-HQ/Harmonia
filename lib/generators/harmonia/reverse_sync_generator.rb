# frozen_string_literal: true

module Harmonia
  module Generators
    class ReverseSyncGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      argument :name, type: :string, required: true, banner: "ModelName"

      def create_sync_file
        template "activerecord_to_filemaker_syncer_template.rb", "app/syncers/#{file_name}_to_filemaker_syncer.rb"
      end

      def generate_migration
        migration_template "add_filemaker_id_to_table.rb", "db/migrate/add_filemaker_id_to_#{table_name}.rb"
      end

      def show_readme
        readme_content = <<~README

          ========================================
          #{class_name}ToFileMakerSyncer has been generated!
          ========================================

          Files created:
          - app/syncers/#{file_name}_to_filemaker_syncer.rb
          - db/migrate/..._add_filemaker_id_to_#{table_name}.rb

          Next steps:
          1. Run migrations: rails db:migrate

          2. Implement the #{class_name}.to_fm method in your model:
             class #{class_name} < ApplicationRecord
               def self.to_fm(record)
                 {
                   'FieldMakerFieldName' => record.attribute_name,
                   # ... map other fields
                 }
               end
             end

          3. Implement the records_to_create method
             - Set @total_create_required to the total number of records that should be created
             - Return an array of ActiveRecord records to create in FileMaker

          4. Implement the records_to_update method
             - Set @total_update_required to the total number of records that should be updated
             - Return an array of ActiveRecord records to update in FileMaker

          5. Implement the find_filemaker_record method
             - Find corresponding FileMaker record for a given ActiveRecord record

          6. Implement the records_to_delete method (optional)
             - Return an array of FileMaker record IDs to delete

          Note: The total_required count used for sync tracking is automatically calculated
          from @total_create_required + @total_update_required

        README

        say readme_content, :green if behavior == :invoke
      end

      # Required for migration_template to work
      def self.next_migration_number(dirname)
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end

      private

      def file_name
        name.underscore
      end

      def class_name
        name.camelize
      end

      def table_name
        name.underscore.pluralize
      end
    end
  end
end

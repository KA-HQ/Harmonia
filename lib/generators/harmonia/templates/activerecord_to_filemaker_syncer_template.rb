# frozen_string_literal: true

class <%= class_name %>ToFileMakerSyncer
  attr_accessor :database_connector

  def initialize(database_connector)
    @database_connector = database_connector
    @last_synced_on = Harmonia::Sync.last_sync_for('<%= table_name %>', 'ActiveRecord to FileMaker')&.ran_on || (Time.now - 15.years)
  end

  # Main sync method
  # Executes the sync process for <%= class_name %> records to FileMaker
  def run
    raise StandardError, 'No database connector set' if @database_connector.blank?

    sync_record = create_sync_record

    @database_connector.open_database do
      sync_record.start!
      sync_records(sync_record)
    end
  rescue StandardError => e
    sync_record&.fail!(e.message)
    raise
  end

  private

  def sync_records(sync_record)
    created_count = create_records
    updated_count = update_records
    delete_records

    total_synced = created_count + updated_count
    total_required = (@total_create_required || 0) + (@total_update_required || 0)

    sync_record.finish!(
      records_synced: total_synced,
      records_required: total_required
    )
  end

  # Returns an array of ActiveRecord records that need to be created in FileMaker
  # Use <%= class_name %>.to_fm(record) to convert to FileMaker attributes
  # Set @total_create_required to the total number of records that should exist after creation
  # @return [Array<<%= class_name %>>] Array of ActiveRecord records
  def records_to_create
    # TODO: Implement logic to fetch records from PostgreSQL that need to be created in FileMaker
    # Example:
    # pg_records = <%= class_name %>.all
    # @total_create_required = pg_records.length
    # existing_ids = YourTrophoniusModel.all.map { |r| r.field_data['PostgreSQLID'] }
    # pg_records.reject { |record| existing_ids.include?(record.id.to_s) }
    @total_create_required = 0
    []
  end

  # Returns an array of ActiveRecord records that need to be updated in FileMaker
  # Use <%= class_name %>.to_fm(record) to convert to FileMaker attributes
  # Set @total_update_required to the total number of records that should be updated
  # @return [Array<<%= class_name %>>] Array of ActiveRecord records
  def records_to_update
    # TODO: Implement logic to fetch records from PostgreSQL that need to be updated in FileMaker
    # Example:
    # pg_records = <%= class_name %>.where('updated_at > ?', 1.hour.ago)
    # records_needing_update = pg_records.select { |pg_record|
    #   fm_record = find_filemaker_record(pg_record)
    #   fm_record && needs_update?(pg_record, fm_record)
    # }
    # @total_update_required = records_needing_update.length
    # records_needing_update
    @total_update_required = 0
    []
  end

  # Returns an array of FileMaker record IDs that need to be deleted
  # @return [Array] Array of FileMaker record IDs
  def records_to_delete
    # TODO: Implement logic to determine which FileMaker records should be deleted
    # Example:
    # pg_ids = <%= class_name %>.pluck(:id).map(&:to_s)
    # YourTrophoniusModel.all.select { |fm_record|
    #   !pg_ids.include?(fm_record.field_data['PostgreSQLID'])
    # }.map(&:record_id)
    []
  end

  def create_records
    records = records_to_create
    return 0 if records.empty?

    records.each do |pg_record|
      fm_attributes = pg_record.to_fm
      YourTrophoniusModel.create(fm_attributes)
    end

    records.size
  end

  def update_records
    records = records_to_update
    return 0 if records.empty?

    records.each do |pg_record|
      fm_attributes = pg_record.to_fm

      # Find the FileMaker record by PostgreSQL ID or other unique identifier
      fm_record = find_filemaker_record(pg_record)
      next unless fm_record

      fm_record.update(fm_attributes)
    end

    records.size
  end

  def delete_records
    record_ids = records_to_delete
    return if record_ids.empty?

    record_ids.each do |record_id|
      fm_record = YourTrophoniusModel.find(record_id)
      fm_record.destroy
    rescue Trophonius::RecordNotFoundError
      # Record already deleted, skip
      next
    end
  end

  # Helper method to find a FileMaker record based on a PostgreSQL record
  # @param pg_record [ActiveRecord::Base] The PostgreSQL record
  # @return [Trophonius::Model, nil] The corresponding FileMaker record or nil
  def find_filemaker_record(pg_record)
    # TODO: Implement logic to find the corresponding FileMaker record
    # Example:
    # YourTrophoniusModel.find_by_field('PostgreSQLID', pg_record.id.to_s)
    nil
  end

  # Determine if a FileMaker record needs to be updated based on PostgreSQL record
  # @param pg_record [ActiveRecord::Base] The PostgreSQL record
  # @param fm_record [Trophonius::Model] The FileMaker record
  # @return [Boolean] true if update is needed
  def needs_update?(pg_record, fm_record)
    # TODO: Implement your comparison logic
    # Example:
    # fm_attributes = pg_record.to_fm
    # fm_attributes.any? { |key, value| fm_record.field_data[key.to_s] != value }
    true
  end

  def create_sync_record
    Harmonia::Sync.create!(
      table: '<%= table_name %>',
      ran_on: Time.now,
      status: 'pending',
      direction: 'ActiveRecord to FileMaker'
    )
  end
end

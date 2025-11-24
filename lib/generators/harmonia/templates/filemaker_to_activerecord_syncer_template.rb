# frozen_string_literal: true

class <%= class_name %>Syncer
  attr_accessor :database_connector

  def initialize(database_connector)
    @database_connector = database_connector
    @last_synced_on = Harmonia::Sync.last_sync_for('<%= table_name %>', 'FileMaker to ActiveRecord')&.ran_on || (Time.now - 15.year)
    @failed_fm_ids = {}
    @failed_pg_ids = {}
  end

  # Main sync method
  # Executes the sync process for <%= class_name %> records
  def run
    raise StandardError, 'No database connector set' if @database_connector.blank?

    sync_record = create_sync_record

    @database_connector.open_database do
      sync_record.start!
      sync_records(sync_record)
    end
  rescue StandardError => e
    sync_record&.fail!(e.message, failed_fm_ids: @failed_fm_ids, failed_pg_ids: @failed_pg_ids)
    raise
  end

  private

  def sync_records(sync_record)
    updated_count = update_records
    created_count = create_records
    delete_records

    total_synced = created_count + updated_count
    total_required = (@total_create_required || 0) + (@total_update_required || 0)

    sync_record.finish!(
      records_synced: total_synced,
      records_required: total_required,
      failed_fm_ids: @failed_fm_ids,
      failed_pg_ids: @failed_pg_ids
    )
  end

  # Returns an array of Trophonius records that need to be created
  # Use FileMaker::<%= class_name %>.to_pg(record) to convert to PostgreSQL attributes
  # Set @total_create_required to the total number of records that should exist after creation
  # @return [Array<Trophonius::Record>] Array of Trophonius records
  def records_to_create
    # TODO: Implement logic to fetch records from FileMaker that need to be created in PostgreSQL
    # Example:
    filemaker_records = FileMaker::<%= class_name %>.where(creation_timestamp: ">= #{@last_synced_on.to_fm}").not
    @total_create_required = filemaker_records.length
    existing_ids = <%= class_name %>.pluck(:filemaker_id)
    filemaker_records.reject { |record| existing_ids.include?(record.id) }
  end

  # Returns an array of Trophonius records that need to be updated
  # Use FileMaker::<%= class_name %>.to_pg(record) to convert to PostgreSQL attributes
  # Set @total_update_required to the total number of records that should be updated
  # @return [Array<Trophonius::Record>] Array of Trophonius records
  def records_to_update
    # TODO: Implement logic to fetch records from FileMaker that need to be updated in PostgreSQL
    # Example:
    filemaker_records = FileMaker::<%= class_name %>.where(modification_timestamp: ">= #{@last_synced_on.to_fm}")
    records_needing_update = filemaker_records.select { |fm_record|
      pg_record = <%= class_name %>.find_by(filemaker_id: fm_record.record_id)
      pg_record && needs_update?(fm_record, pg_record)
    }
    @total_update_required = records_needing_update.length
    records_needing_update
  end

  # Returns an array of record identifiers that need to be deleted
  # @return [Array] Array of record identifiers
  def records_to_delete
    # Get all modified FileMaker record IDs
    filemaker_records = FileMaker::<%= class_name %>.where(modification_timestamp: ">= #{@last_synced_on.to_fm}")
    fm_ids = filemaker_records.map(&:record_id)

    # Find PostgreSQL records whose FileMaker IDs aren't in the modified set
    # These might have been deleted in FileMaker
    fm_ids_no_update_needed = <%= class_name %>.where.not(filemaker_id: fm_ids).pluck(:filemaker_id)
    return [] if fm_ids_no_update_needed.empty?

    # Query FileMaker to check if these records still exist
    possibly_deleted_query = FileMaker::<%= class_name %>.where(record_id: fm_ids_no_update_needed.first)
    fm_ids_no_update_needed.count > 1 && fm_ids_no_update_needed[1..].each do |fm_id|
      possibly_deleted_query.or(record_id: fm_id)
    end

    # Find IDs that exist in PostgreSQL but not in FileMaker (truly deleted)
    deleted_fm_ids = fm_ids_no_update_needed - possibly_deleted_query.map(&:record_id)

    # Return PostgreSQL IDs for records with these FileMaker IDs
    <%= class_name %>.where(filemaker_id: deleted_fm_ids).pluck(:id)
  end

  def needs_update?(fm_record, pg_record)
    pg_attributes = FileMaker::<%= class_name %>.to_pg(fm_record)

    pg_attributes.any? { |key, value| pg_record.send(key) != value }
  end

  def create_records
    records = records_to_create
    return 0 if records.empty?

    success_count = 0

    records.each do |trophonius_record|
      begin
        attributes = FileMaker::<%= class_name %>.to_pg(trophonius_record).merge(
          created_at: Time.current,
          updated_at: Time.current
        )
        <%= class_name %>.create!(attributes)
        success_count += 1
      rescue StandardError => e
        @failed_fm_ids[trophonius_record.record_id.to_s] = e.message
        Rails.logger.error("Failed to create record from FileMaker ID #{trophonius_record.record_id}: #{e.message}")
      end
    end

    success_count
  end

  def update_records
    records = records_to_update
    return 0 if records.empty?

    success_count = 0

    records.each do |trophonius_record|
      begin
        pg_attributes = FileMaker::<%= class_name %>.to_pg(trophonius_record)

        <%= class_name %>.where(filemaker_id: trophonius_record.record_id).update_all(
          pg_attributes.merge(updated_at: Time.current)
        )
        success_count += 1
      rescue StandardError => e
        @failed_fm_ids[trophonius_record.record_id.to_s] = e.message
        Rails.logger.error("Failed to update record from FileMaker ID #{trophonius_record.record_id}: #{e.message}")
      end
    end

    success_count
  end

  def delete_records
    ids = records_to_delete
    return if ids.empty?

    ids.each do |pg_id|
      begin
        <%= class_name %>.where(id: pg_id).destroy_all
      rescue StandardError => e
        @failed_pg_ids[pg_id.to_s] = e.message
        Rails.logger.error("Failed to delete record with PostgreSQL ID #{pg_id}: #{e.message}")
      end
    end
  end

  def create_sync_record
    Harmonia::Sync.create!(
      table: '<%= table_name %>',
      ran_on: Time.now,
      status: 'pending',
      direction: 'FileMaker to ActiveRecord'
    )
  end
end

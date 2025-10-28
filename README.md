# Harmonia

[![Gem Version](https://badge.fury.io/rb/harmonia.svg)](https://badge.fury.io/rb/harmonia)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Harmonia is a Rails generator gem that creates synchronization logic between FileMaker databases and Ruby on Rails ActiveRecord models. It leverages the [Trophonius gem](https://github.com/KA-HQ/trophonius) for FileMaker Data API communication.

## Origin of the Name

Harmonia is named after the Greek goddess of harmony and concord. In Greek mythology, [Harmonia](https://en.wikipedia.org/wiki/Harmonia) was the immortal goddess who reconciled opposing forces and brought them into balance. Just as the goddess brought harmony between different elements, this gem achieves harmony and concord between FileMaker databases and ActiveRecord databases, bridging two different data systems into a synchronized whole.

## Features

- **Automated Sync Generation**: Generate syncer classes for your models with a single command
- **Sync Tracking**: Built-in model to track synchronization status, completion, and errors
- **Flexible Architecture**: Customize creation, update, and deletion logic for your specific needs
- **Connection Management**: Automatic FileMaker connection handling with proper cleanup
- **Extensible**: Override methods to implement custom sync logic

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'harmonia'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install harmonia
```

## Getting Started

### 1. Install Harmonia

Run the install generator to set up the necessary files and database tables:

```bash
rails generate harmonia:install
```

This will create:

- `app/services/database_connector.rb` - Manages FileMaker connections
- `config/initializers/trophonius_model_extension.rb` - Extends Trophonius models
- `app/models/harmonia/sync.rb` - Tracks sync operations
- `db/migrate/[timestamp]_create_harmonia_syncs.rb` - Migration for sync tracking table

After generation, remember to:

1. Replace all instances of `YourTrophoniusModel` with your actual Trophonius model names
2. Update the `database` configuration in `database_connector.rb`
3. Run the migration: `rails db:migrate`

### 2. Configure FileMaker Credentials

Add your FileMaker credentials to your Rails credentials file:

```bash
rails credentials:edit
```

Add the following:

```yaml
filemaker:
  username: your_username
  password: your_password
```

### 3. Create a Trophonius Model

Define your FileMaker model using Trophonius. For example:

```ruby
# app/models/trophonius/product.rb
module Trophonius
  class Product < Trophonius::Model
    config layout_name: 'ProductsLayout'

    # Convert FileMaker record to PostgreSQL attributes
    def self.to_pg(record)
      {
        filemaker_id: record.id,
        name: record.product_name,
        price: record.price,
        sku: record.sku
      }
    end
  end
end
```

### 4. Generate a Syncer

Generate a syncer for your model:

```bash
rails generate harmonia:sync Product
```

This creates `app/syncers/product_syncer.rb` with the basic structure.

### 5. Implement Sync Logic

Edit the generated syncer to implement your synchronization logic:

```ruby
# app/syncers/product_syncer.rb
class ProductSyncer
  attr_accessor :database_connector

  def initialize(database_connector)
    @database_connector = database_connector
  end

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

  def records_to_create
    filemaker_records = Trophonius::Product.all
    @total_create_required = filemaker_records.length

    existing_ids = Product.pluck(:filemaker_id)
    filemaker_records.reject { |record| existing_ids.include?(record.record_id) }
  end

  def records_to_update
    filemaker_records = Trophonius::Product.all

    records_needing_update = filemaker_records.select { |fm_record|
      pg_record = Product.find_by(filemaker_id: fm_record.record_id)
      pg_record && needs_update?(fm_record, pg_record)
    }

    @total_update_required = records_needing_update.length
    records_needing_update
  end

  def records_to_delete
    filemaker_ids = Trophonius::Product.all.map(&:record_id)
    Product.where.not(filemaker_id: filemaker_ids).pluck(:id)
  end

  def needs_update?(fm_record, pg_record)
    # Implement your comparison logic
    fm_data = Trophonius::Product.to_pg(fm_record)
    pg_record.name != fm_data[:name] || pg_record.price != fm_data[:price]
  end

  # ... other methods (create_records, update_records, etc.)
end
```

### 6. Run Your Sync

```ruby
# Create a database connector
connector = DatabaseConnector.new
connector.hostname = 'your-filemaker-server.com'

# Initialize and run the syncer
syncer = ProductSyncer.new(connector)
syncer.run
```

## Architecture

### Key Components

#### 1. DatabaseConnector

Manages connections to the FileMaker server using Trophonius:

```ruby
connector = DatabaseConnector.new
connector.hostname = 'filemaker.example.com'

connector.open_database do
  # Your FileMaker operations here
end
# Connection automatically closed
```

#### 2. Syncer Classes

Each syncer handles the synchronization logic for a specific model:

- **`records_to_create`**: Returns records that need to be created in PostgreSQL
  - Must set `@total_create_required` to track total records
- **`records_to_update`**: Returns records that need to be updated
  - Must set `@total_update_required` to track total records
- **`records_to_delete`**: Returns records that should be deleted
- **`create_records`**: Bulk creates new records
- **`update_records`**: Updates existing records
- **`delete_records`**: Removes obsolete records

#### 3. Harmonia::Sync Model

Tracks sync operations with the following attributes:

- `table` - Name of the table being synced
- `ran_on` - Date the sync was run
- `status` - One of: `pending`, `in_progress`, `completed`, `failed`
- `records_synced` - Number of records successfully synced
- `records_required` - Total number of records that should exist
- `error_message` - Error details if sync failed

**Important**: The `records_required` value is automatically calculated as:

```ruby
total_required = (@total_create_required || 0) + (@total_update_required || 0)
```

You must set `@total_create_required` in `records_to_create` and `@total_update_required` in `records_to_update`.

#### Useful Methods

```ruby
# Get the last sync for a table
Harmonia::Sync.last_sync_for('products')

# Check completion percentage
sync = Harmonia::Sync.last
sync.completion_percentage # => 98.5

# Check if sync was complete
sync.complete? # => true if all records synced

# Query by status
Harmonia::Sync.completed
Harmonia::Sync.failed
Harmonia::Sync.in_progress
```

### Trophonius Model Extension

The `to_pg` class method is required on all Trophonius models:

```ruby
module Trophonius
  class Product < Trophonius::Model
    def self.to_pg(record)
      {
        filemaker_id: record.record_id,
        name: record.field_data['ProductName'],
        price: record.field_data['Price'].to_f,
        # ... map other fields
      }
    end
  end
end
```

## Advanced Usage

### Custom Comparison Logic

Implement `needs_update?` to define when a record should be updated:

```ruby
def needs_update?(fm_record, pg_record)
  fm_data = Trophonius::Product.to_pg(fm_record)

  # Compare specific fields
  pg_record.name != fm_data[:name] ||
    pg_record.price != fm_data[:price] ||
    pg_record.updated_at < 1.day.ago
end
```

### Batch Processing

For large datasets, consider processing in batches:

```ruby
def create_records
  records = records_to_create
  return 0 if records.empty?

  records.each_slice(1000) do |batch|
    attributes_array = batch.map do |trophonius_record|
      Trophonius::Product.to_pg(trophonius_record).merge(
        created_at: Time.current,
        updated_at: Time.current
      )
    end

    Product.insert_all(attributes_array)
  end

  records.size
end
```

### Scheduled Syncs

Use a background job processor like Sidekiq:

```ruby
class ProductSyncJob < ApplicationJob
  queue_as :default

  def perform
    connector = DatabaseConnector.new
    connector.hostname = ENV['FILEMAKER_HOST']

    syncer = ProductSyncer.new(connector)
    syncer.run
  end
end

# Schedule with cron or similar
# 0 2 * * * # Every day at 2 AM
```

### Multiple FileMaker Databases

Configure different connectors for different databases:

```ruby
class DatabaseConnector
  attr_accessor :hostname, :database_name

  def connect
    Trophonius.configure do |config|
      config.host = @hostname
      config.database = @database_name
      # ... other config
    end
  end
end

# Usage
connector = DatabaseConnector.new
connector.hostname = 'filemaker.example.com'
connector.database_name = 'Products'
```

## Error Handling

Syncers automatically handle errors and mark syncs as failed:

```ruby
def run
  sync_record = create_sync_record

  @database_connector.open_database do
    sync_record.start!
    sync_records(sync_record)
  end
rescue StandardError => e
  sync_record&.fail!(e.message)
  raise
end
```

Check failed syncs:

```ruby
failed_syncs = Harmonia::Sync.failed.recent
failed_syncs.each do |sync|
  puts "#{sync.table}: #{sync.error_message}"
end
```

## Configuration Options

### Trophonius Pool Size

Adjust connection pool size for better performance:

```ruby
# In database_connector.rb
config.pool_size = ENV.fetch('TROPHONIUS_POOL', 5)
```

Set in your environment:

```bash
TROPHONIUS_POOL=10
```

### SSL Configuration

Enable or disable SSL for FileMaker connections:

```ruby
config.ssl = true  # Use HTTPS
config.ssl = false # Use HTTP
```

### Debug Mode

Enable detailed logging:

```ruby
config.debug = true
```

## Testing

### RSpec Example

```ruby
require 'rails_helper'

RSpec.describe ProductSyncer do
  let(:connector) { instance_double(DatabaseConnector) }
  let(:syncer) { described_class.new(connector) }

  describe '#records_to_create' do
    it 'returns records not in PostgreSQL' do
      # Mock FileMaker records
      allow(Trophonius::Product).to receive(:all).and_return([
        double(record_id: 1),
        double(record_id: 2)
      ])

      # Mock existing PostgreSQL records
      allow(Product).to receive(:pluck).with(:filemaker_id).and_return([1])

      result = syncer.send(:records_to_create)
      expect(result.map(&:record_id)).to eq([2])
    end
  end
end
```

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to FileMaker server

**Solutions**:

- Verify hostname and credentials
- Check if FileMaker Data API is enabled
- Ensure SSL settings match your server configuration
- Check firewall rules allow connections to port 443 (HTTPS) or 80 (HTTP)

### Missing Records

**Problem**: Not all records are syncing

**Solutions**:

- Verify `records_to_create` and `records_to_update` logic
- Check FileMaker layouts include all necessary fields
- Ensure `to_pg` mapping is correct
- Review sync completion percentage

### Performance Issues

**Problem**: Syncs are slow

**Solutions**:

- Increase `pool_size` in Trophonius configuration
- Implement batch processing
- Use `insert_all` instead of individual inserts
- Add database indexes on `filemaker_id` columns
- Consider partial syncs for large datasets

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/KA-HQ/Harmonia.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Credits

Developed by [Kempen Automatisering](https://www.kempenautomatisering.nl)

Built on top of the excellent [Trophonius](https://github.com/KA-HQ/trophonius) gem for FileMaker Data API integration.

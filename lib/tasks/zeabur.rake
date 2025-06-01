namespace :zeabur do
  desc "Check PostgreSQL environment variables"
  task check_postgres_env: :environment do
    puts "Checking PostgreSQL environment variables..."

    env_vars = %w[
      POSTGRES_CONNECTION_STRING
      POSTGRES_URI
      POSTGRES_HOST
      POSTGRES_DATABASE
      POSTGRES_USERNAME
      POSTGRES_PASSWORD
      POSTGRES_PORT
    ]

    env_vars.each do |var|
      value = ENV[var]
      if value
        # Mask password for security
        display_value = var.include?("PASSWORD") ? "*" * value.length : value
        puts "✓ #{var}: #{display_value}"
      else
        puts "✗ #{var}: not set"
      end
    end
  end

  desc "Check Active Storage configuration"
  task check_active_storage: :environment do
    puts "Checking Active Storage configuration..."

    puts "Current service: #{Rails.application.config.active_storage.service}"

    # Check storage configuration
    storage_config = Rails.application.config_for(:storage)
    puts "Available storage services: #{storage_config.keys.join(', ')}"

    # Check cloud storage environment variables
    cloud_vars = {
      "AWS S3" => %w[AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION AWS_BUCKET],
      "Google Cloud Storage" => %w[GCS_PROJECT GCS_BUCKET GOOGLE_APPLICATION_CREDENTIALS],
      "Azure Storage" => %w[AZURE_STORAGE_ACCOUNT_NAME AZURE_STORAGE_ACCESS_KEY AZURE_CONTAINER]
    }

    cloud_vars.each do |service, vars|
      puts "\n#{service} configuration:"
      vars.each do |var|
        value = ENV[var]
        if value
          display_value = var.include?("SECRET") || var.include?("KEY") ? "*" * 8 : value
          puts "  ✓ #{var}: #{display_value}"
        else
          puts "  ✗ #{var}: not set"
        end
      end
    end
  end

  desc "Check Zeabur Volumes configuration"
  task check_volumes: :environment do
    puts "Checking Zeabur Volumes configuration..."

    storage_path = Rails.root.join("storage")

    puts "Storage directory: #{storage_path}"
    puts "Directory exists: #{Dir.exist?(storage_path) ? '✓' : '✗'}"

    if Dir.exist?(storage_path)
      puts "Directory readable: #{File.readable?(storage_path) ? '✓' : '✗'}"
      puts "Directory writable: #{File.writable?(storage_path) ? '✓' : '✗'}"

      # Check if it's likely a mounted volume (different filesystem)
      begin
        stat = File.stat(storage_path)
        puts "Directory permissions: #{sprintf('%o', stat.mode)}"
        puts "Owner UID: #{stat.uid}"
        puts "Owner GID: #{stat.gid}"

        # Try to create a test file
        test_file = storage_path.join(".zeabur_volume_test")
        File.write(test_file, "test")
        File.delete(test_file)
        puts "Write test: ✓ Success"
      rescue => e
        puts "Write test: ✗ Failed - #{e.message}"
      end
    else
      puts "⚠️  Storage directory does not exist. Creating..."
      begin
        FileUtils.mkdir_p(storage_path)
        puts "✓ Storage directory created"
      rescue => e
        puts "✗ Failed to create storage directory: #{e.message}"
      end
    end

    # Check Active Storage service configuration
    service = Rails.application.config.active_storage.service
    puts "\nActive Storage service: #{service}"

    if service == :local
      puts "✓ Using local storage (compatible with Zeabur Volumes)"
    else
      puts "ℹ️  Using cloud storage (#{service})"
    end
  end

  desc "Check Rails 8 components (Solid Queue, Solid Cache, Solid Cable)"
  task check_rails8_components: :environment do
    puts "Checking Rails 8 components..."

    # Check Solid Queue tables
    solid_queue_tables = %w[solid_queue_jobs solid_queue_scheduled_executions solid_queue_claimed_executions solid_queue_blocked_executions solid_queue_failed_executions solid_queue_pauses solid_queue_processes solid_queue_ready_executions solid_queue_recurring_executions]

    puts "\nSolid Queue tables:"
    solid_queue_tables.each do |table|
      exists = ActiveRecord::Base.connection.table_exists?(table)
      puts "  #{table}: #{exists ? '✓' : '✗'}"
    end

    # Check Solid Cache tables
    solid_cache_tables = %w[solid_cache_entries]

    puts "\nSolid Cache tables:"
    solid_cache_tables.each do |table|
      exists = ActiveRecord::Base.connection.table_exists?(table)
      puts "  #{table}: #{exists ? '✓' : '✗'}"
    end

    # Check Solid Cable tables
    solid_cable_tables = %w[solid_cable_messages]

    puts "\nSolid Cable tables:"
    solid_cable_tables.each do |table|
      exists = ActiveRecord::Base.connection.table_exists?(table)
      puts "  #{table}: #{exists ? '✓' : '✗'}"
    end

    # Check Active Storage tables
    active_storage_tables = %w[active_storage_blobs active_storage_attachments active_storage_variant_records]

    puts "\nActive Storage tables:"
    active_storage_tables.each do |table|
      exists = ActiveRecord::Base.connection.table_exists?(table)
      puts "  #{table}: #{exists ? '✓' : '✗'}"
    end
  end

  desc "Load Rails 8 schema files into production database"
  task load_rails8_schemas: :environment do
    puts "Loading Rails 8 schema files into production database..."

    # Load Solid Queue schema
    queue_schema_file = Rails.root.join("db", "queue_schema.rb")
    if File.exist?(queue_schema_file)
      puts "Loading Solid Queue schema..."
      load queue_schema_file
      puts "✓ Solid Queue schema loaded"
    else
      puts "✗ Solid Queue schema file not found"
    end

    # Load Solid Cache schema
    cache_schema_file = Rails.root.join("db", "cache_schema.rb")
    if File.exist?(cache_schema_file)
      puts "Loading Solid Cache schema..."
      load cache_schema_file
      puts "✓ Solid Cache schema loaded"
    else
      puts "✗ Solid Cache schema file not found"
    end

    # Load Solid Cable schema
    cable_schema_file = Rails.root.join("db", "cable_schema.rb")
    if File.exist?(cable_schema_file)
      puts "Loading Solid Cable schema..."
      load cable_schema_file
      puts "✓ Solid Cable schema loaded"
    else
      puts "✗ Solid Cable schema file not found"
    end
  end

  desc "Setup production database with Active Storage and Rails 8 components"
  task setup_production_db: :environment do
    puts "Setting up production database with Rails 8 components..."

    # Create database if it doesn't exist
    begin
      Rake::Task["db:create"].invoke
      puts "✓ Database created"
    rescue => e
      puts "Database already exists or creation failed: #{e.message}"
    end

    # Run regular migrations first
    Rake::Task["db:migrate"].invoke
    puts "✓ Regular migrations completed"

    # Load Rails 8 schema files
    Rake::Task["zeabur:load_rails8_schemas"].invoke

    # Install Active Storage if not already present
    if ActiveRecord::Base.connection.table_exists?("active_storage_blobs")
      puts "✓ Active Storage tables already exist"
    else
      puts "Installing Active Storage..."
      Rake::Task["active_storage:install"].invoke
      Rake::Task["db:migrate"].invoke
      puts "✓ Active Storage installed"
    end

    # Precompile assets
    begin
      Rake::Task["assets:precompile"].invoke
      puts "✓ Assets precompiled"
    rescue => e
      puts "Asset precompilation failed: #{e.message}"
    end

    puts "\n🎉 Production database setup complete!"
    puts "Rails 8 components (Solid Queue, Solid Cache, Solid Cable) and Active Storage are ready!"
  end

  desc "Clean up unused Active Storage attachments"
  task cleanup_attachments: :environment do
    puts "Cleaning up unused Active Storage attachments..."

    # This will remove blobs that are not attached to any records
    ActiveStorage::Blob.unattached.find_each(&:purge_later)

    puts "✓ Cleanup job queued. Unused attachments will be removed in the background."
  end

  desc "Show Active Storage statistics"
  task storage_stats: :environment do
    puts "Active Storage Statistics:"
    puts "========================="

    total_blobs = ActiveStorage::Blob.count
    total_attachments = ActiveStorage::Attachment.count
    total_size = ActiveStorage::Blob.sum(:byte_size)

    puts "Total blobs: #{total_blobs}"
    puts "Total attachments: #{total_attachments}"
    puts "Total storage used: #{ActionController::Base.helpers.number_to_human_size(total_size)}"

    # Group by content type
    puts "\nFiles by type:"
    ActiveStorage::Blob.group(:content_type).count.each do |content_type, count|
      puts "  #{content_type}: #{count} files"
    end

    # Show largest files
    puts "\nLargest files:"
    ActiveStorage::Blob.order(byte_size: :desc).limit(5).each do |blob|
      puts "  #{blob.filename}: #{ActionController::Base.helpers.number_to_human_size(blob.byte_size)}"
    end

    # Show storage directory info if using local storage
    if Rails.application.config.active_storage.service == :local
      storage_path = Rails.root.join("storage")
      if Dir.exist?(storage_path)
        puts "\nLocal storage directory:"
        puts "  Path: #{storage_path}"

        # Calculate directory size
        total_disk_size = 0
        Dir.glob(File.join(storage_path, "**", "*")).each do |file|
          total_disk_size += File.size(file) if File.file?(file)
        end

        puts "  Disk usage: #{ActionController::Base.helpers.number_to_human_size(total_disk_size)}"
        puts "  Files on disk: #{Dir.glob(File.join(storage_path, '**', '*')).count { |f| File.file?(f) }}"
      end
    end
  end

  desc "Run all Zeabur checks"
  task check_all: :environment do
    puts "Running all Zeabur deployment checks...\n"

    Rake::Task["zeabur:check_postgres_env"].invoke
    puts "\n" + "="*50 + "\n"

    Rake::Task["zeabur:check_active_storage"].invoke
    puts "\n" + "="*50 + "\n"

    Rake::Task["zeabur:check_volumes"].invoke
    puts "\n" + "="*50 + "\n"

    Rake::Task["zeabur:check_rails8_components"].invoke
    puts "\n" + "="*50 + "\n"

    puts "🎯 All checks completed!"
  end
end

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
        display_value = var.include?('PASSWORD') ? '*' * value.length : value
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
      'AWS S3' => %w[AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION AWS_BUCKET],
      'Google Cloud Storage' => %w[GCS_PROJECT GCS_BUCKET GOOGLE_APPLICATION_CREDENTIALS],
      'Azure Storage' => %w[AZURE_STORAGE_ACCOUNT_NAME AZURE_STORAGE_ACCESS_KEY AZURE_CONTAINER]
    }
    
    cloud_vars.each do |service, vars|
      puts "\n#{service} configuration:"
      vars.each do |var|
        value = ENV[var]
        if value
          display_value = var.include?('SECRET') || var.include?('KEY') ? '*' * 8 : value
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
    
    storage_path = Rails.root.join('storage')
    
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
        test_file = storage_path.join('.zeabur_volume_test')
        File.write(test_file, 'test')
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

  desc "Setup production database with Active Storage"
  task setup_production_db: :environment do
    puts "Setting up production database with Active Storage..."
    
    Rake::Task['db:create'].invoke
    puts "✓ Database created"
    
    Rake::Task['db:migrate'].invoke
    puts "✓ Database migrated"
    
    # Check if Active Storage tables exist
    if ActiveRecord::Base.connection.table_exists?('active_storage_blobs')
      puts "✓ Active Storage tables already exist"
    else
      puts "Installing Active Storage..."
      Rake::Task['active_storage:install'].invoke
      Rake::Task['db:migrate'].invoke
      puts "✓ Active Storage installed and migrated"
    end
    
    Rake::Task['assets:precompile'].invoke
    puts "✓ Assets precompiled"
    
    puts "\n🎉 Production database setup complete!"
    puts "You can now deploy your application with Active Storage support."
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
      storage_path = Rails.root.join('storage')
      if Dir.exist?(storage_path)
        puts "\nLocal storage directory:"
        puts "  Path: #{storage_path}"
        
        # Calculate directory size
        total_disk_size = 0
        Dir.glob(File.join(storage_path, '**', '*')).each do |file|
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
    
    Rake::Task['zeabur:check_postgres_env'].invoke
    puts "\n" + "="*50 + "\n"
    
    Rake::Task['zeabur:check_active_storage'].invoke
    puts "\n" + "="*50 + "\n"
    
    Rake::Task['zeabur:check_volumes'].invoke
    puts "\n" + "="*50 + "\n"
    
    puts "🎯 All checks completed!"
  end
end 
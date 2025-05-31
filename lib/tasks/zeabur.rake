namespace :zeabur do
  desc "Check Zeabur PostgreSQL environment variables"
  task :check_postgres_env do
    puts "🔍 Checking Zeabur PostgreSQL Environment Variables..."
    puts "=" * 50
    
    env_vars = [
      'POSTGRES_CONNECTION_STRING',
      'POSTGRES_DATABASE', 
      'POSTGRES_HOST',
      'POSTGRES_PASSWORD',
      'POSTGRES_PORT',
      'POSTGRES_URI',
      'POSTGRES_USERNAME',
      'POSTGRESQL_HOST'
    ]
    
    env_vars.each do |var|
      value = ENV[var]
      if value
        # Mask sensitive information
        if var.include?('PASSWORD') || var.include?('CONNECTION_STRING') || var.include?('URI')
          masked_value = value.length > 4 ? "#{value[0..3]}#{'*' * (value.length - 4)}" : "****"
          puts "✅ #{var}: #{masked_value}"
        else
          puts "✅ #{var}: #{value}"
        end
      else
        puts "❌ #{var}: Not set"
      end
    end
    
    puts "=" * 50
    
    # Test database connection in production environment
    if Rails.env.production?
      puts "🔗 Testing database connection..."
      begin
        ActiveRecord::Base.connection.execute("SELECT 1")
        puts "✅ Database connection successful!"
      rescue => e
        puts "❌ Database connection failed: #{e.message}"
      end
    else
      puts "ℹ️  Database connection test skipped (not in production environment)"
    end
  end
  
  desc "Setup database for production deployment"
  task :setup_production_db => :environment do
    if Rails.env.production?
      puts "🚀 Setting up production database..."
      
      begin
        # Create database if it doesn't exist
        Rake::Task['db:create'].invoke
        puts "✅ Database created (or already exists)"
        
        # Run migrations
        Rake::Task['db:migrate'].invoke
        puts "✅ Migrations completed"
        
        # Precompile assets
        Rake::Task['assets:precompile'].invoke
        puts "✅ Assets precompiled"
        
        puts "🎉 Production setup completed successfully!"
      rescue => e
        puts "❌ Production setup failed: #{e.message}"
        exit 1
      end
    else
      puts "⚠️  This task should only be run in production environment"
    end
  end
end 
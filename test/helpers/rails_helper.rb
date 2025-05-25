begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }
RSpec.configure do |config|
  config.include ApiHelpers, type: :request
  # ... other configurations
end
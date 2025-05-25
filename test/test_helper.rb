ENV["RAILS_ENV"] ||= "test"
ENV['JWT_SECRET_KEY'] ||= 'dsadwadsdsafsfwafrgrdesdwqhtrjuyjkuyoi87'
require_relative "../config/environment"
require "rails/test_help"
require "factory_bot_rails"

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  include FactoryBot::Syntax::Methods
end
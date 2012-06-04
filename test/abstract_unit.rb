require 'test/unit'

require 'active_record'
require 'active_record/fixtures'
require 'active_record/test_case'

# Search for fixtures first
fixture_path = File.dirname(__FILE__) + '/fixtures/'
ActiveSupport::Dependencies.autoload_paths.unshift(fixture_path)

ActiveRecord::Base.configurations = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = ActiveSupport::BufferedLogger.new(File.dirname(__FILE__) + '/debug.log')
ActiveRecord::Base.establish_connection(ENV['DB'] || 'mysql')

require "./lib/acts_as_ordered.rb"

load(File.dirname(__FILE__) + '/schema.rb')

class ActiveRecord::TestCase #:nodoc:
  include ActiveRecord::TestFixtures

  self.fixture_path = File.dirname(__FILE__) + '/fixtures/'

  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
end

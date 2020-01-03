require "bundler/setup"
require "mdmm"

# Set variable to know when testing.
# Also has boolean value true.
ENV['TEST'] = 'rspec'
puts "ENV['TEST']: #{ENV['TEST']}"

RSpec.configure do |config|
  include Mdmm

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require 'simplecov'
SimpleCov.start

require 'coveralls'
Coveralls.wear!

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
   Coveralls::SimpleCov::Formatter,
]

SimpleCov.configure do
  add_filter '/spec/'
end

require 'bundler/setup'
Bundler.require(:default, :development)

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.filter_run_excluding perf: true
  config.order = 'random'
end

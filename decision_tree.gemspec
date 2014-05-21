# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'decision_tree/version'

Gem::Specification.new do |spec|
  spec.name          = "decision_tree"
  spec.version       = DecisionTree::VERSION
  spec.authors       = ["Jason Langenauer", "John D'Agostino"]
  spec.email         = ["john.dagostino@gmail.com", "jasonl@jobready.com.au"]
  spec.summary       = %q{Create simple decision tree/rules}
  spec.description   = %q{Create simple decision tree/rules for workflow building}
  spec.homepage      = "https://github.com/jobready/decision_tree"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec', '~> 2.14'
  spec.add_development_dependency 'cane', '~> 2.6'
  spec.add_development_dependency 'byebug', '~> 2.7'
  spec.add_development_dependency 'coveralls'
  spec.add_dependency 'activesupport'
end

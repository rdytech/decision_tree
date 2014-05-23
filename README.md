# Decision Tree

Decision Tree is an easy way of defining rules/workflows

## Installation

Add this line to your application's Gemfile:

    gem 'decision_tree'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install decision_tree

## Usage

```ruby
class TestWorkflow < DecisionTree::Workflow
  def decision_method
    true
  end

  decision :decision_method do
    yes { it_returned_true }
    no { it_returned_false }
  end

  start do
    decision_method
  end
end

TestWorkflow.new
```

Implementing State

```ruby
class Change < ActiveRecord::Base
  attr_accessible :state
  
  def start_workflow(&block)
    with_lock do
      yield 
    end
  end
end
```

## Contributing

1. Fork it ( http://github.com/jobready/decision_tree/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

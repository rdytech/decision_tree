# Decision Tree

Decision Tree is an easy way of defining rules/workflows that progress an
object's state through a series of boolean decisions.

## Installation

Add this line to your application's Gemfile:

    gem 'decision_tree'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install decision_tree

## Usage

Define your workflow by inheriting from `DecisionTree::Workflow`. A `start`
method is required, and will be the entry point into the decision tree.

The actual decisions are declared using the `decision` macro. This takes a
single parameter, which is the name of the method that actually makes the
decision. When called, the decision macro will invoke this method, then
act according to the truthiness of the response returned - invoking the
code in its `yes` block for true, and `no` block for false.

To accommodate interruptions to the decision tree, perhaps at locations where
user input is required, the `entry` macro can be used to define new entry
points. This macro takes the name of the entry point, and can be invoked by
calling this method from outside the workflow class.

For both decision and entry macros, the correspondingly named method *must*
exist in the class, even if it only returns `true`.

```ruby
class TestWorkflow < DecisionTree::Workflow
  def decision_method
    true
  end

  def reviewed_by_staff
    true
  end

  decision :decision_method do
    yes { it_returned_true }
    no { it_returned_false }
  end

  start do
    decision_method
  end

  entry :reviewed_by_staff do
    decision_method
  end
end

TestWorkflow.new(state_object)
```

##Implementing State

Decision trees are intended to be instantiated many times, but in order to
preserve idempotence, there needs to be an object to hold the state between
invocations. This will typically be an ActiveRecord model, with the state
stored in the database.

The state carrier needs to implement a `state!` method that persists the state
(a string) passed to it, and a `start_workflow` method that needs to yield
into the passed block, which is a good place to ensure locks are in place to
guard against simultaneous invocations of the workflow.

```ruby
class Change < ActiveRecord::Base

  def state!(new_state)
    update_attributes(state: new_state)
  end

  def start_workflow(&block)
    with_lock do
      yield
    end
  end
end
```

##Displaying the Workflow
Human readable display of workflow steps can be achieved by using `DecisionTree::Step#display`.
E.g.

```ruby
- workflow.steps.each do |step|
  = step.display
```

The value returned by this will either be one set explicitly in the translations, or one implicitly derived from the step name.


### Explicit Display Values
Human readable translations are defined under `workflow_steps`.

E.g.:

    workflow_steps:
      entry_point:
        __start_workflow: 'Decision Workflow Started'
        reviewed_by_etd!: 'ETD has reviewed the provided evidence'
      idempotent_call:
        mark_for_review!: 'Waiting on ETD to review evidence'
      approval_only_required_from_initiator?:
        'yes': 'Approval is only required from the initiator'
        'no': 'This change must be approved by more than the initiator'

Any entry point into the workflow is defined under `entry_point`, including the initial one that is automatically created by the gem (`__start_workflow`).
Any idempotent calls (identified by a trailing `!`) are defined under `idempotent_call`.

Any regular steps (with a yes/no outcome) are defined directly under `workflow_steps`, and contain values for both 'yes', and 'no'. Note that these keys should be defined as strings (explicitly wrapped in quotes), otherwise YAML helpfully converts these to booleans, which will not be matched when looking for a description.

### Implicit Display Values
Semi-friendly display values are still returned if no translation has been defined.  
For a regular step, the question will be rendered, followed by the answer.

```
# method name: is_contract_full_time?
# answer is 'NO'
step.display # => Is contract full time? - No

```

Entry points and idempotent calls are also slightly humanised.

```
:reviewed_by_etd! # => Reviewed by etd!
```


## Contributing

1. Fork it ( http://github.com/jobready/decision_tree/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## Style guidelines

We try to adhere to the following coding style guidelines

  * https://github.com/styleguide/ruby
  * https://github.com/bbatsov/rails-style-guide
  * https://github.com/bbatsov/ruby-style-guide

## Git Workflow

  * https://github.com/nvie/gitflow
  * http://nvie.com/posts/a-successful-git-branching-model/
  * http://danielkummer.github.io/git-flow-cheatsheet/

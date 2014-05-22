require 'logger'
require 'active_support/all'

# Base class from which the actual workflows are derived. It's designed to
# persist enough state in the store to allow the workflow to be repeatedly
# and simultaneously instantiated, and transition into the current state
# permitted by the workflow.
class DecisionTree::Workflow
  class YesAndNoRequiredError < StandardError; end
  class MethodNotDefinedError < StandardError; end

  attr_reader :store
  attr_reader :redirect
  attr_reader :notifications
  attr_accessor :logger
  attr_reader :steps # Temporary - should we persist this?

  def initialize(store=nil)
    @store = store || DecisionTree::Store.new
    @steps = []
    @notifications = []
    initialize_persistent_state(store.state)
    @proxy = DecisionTree::Proxy.new(self)

    # We're using pessimistic locking here, so this will block until an
    # exclusive lock can be obtained on the change.
    store.start do
      catch :exit do
        if @entry_points.empty?
          send(:__start_workflow)
        else
          # TODO: This should fail silently if an entry point is no longer
          # defined, this will allow for modification of the workflows with
          # existing changes in the DB.
          @entry_points.each { |ep| send(ep) }
        end
      end
      persist_state!
    end
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  private

  # We use a DecisionTree::Store to persist workflow across
  # instantiations of the workflow object, and guarantee idempotency. The
  # actual data is stored as a slug:
  #
  # "entry_point:method_call!/other_call!"
  #
  # where the entry_point is the last entry point into the workflow, and
  # the method calls are records of non-idempotent method calls, which we
  # only want to call once in the lifecycle of the workflow.
  def initialize_persistent_state(workflow_state)
    logger.info workflow_state
    if workflow_state.empty?
      @entry_points = DecisionTree::OrderedSet.new
      @nonidempotent_calls = Set.new
    else
      entries_slug, call_slug = workflow_state.split(':')
      @entry_points = DecisionTree::OrderedSet.new(entries_slug.try(:split, '/')) || DecisionTree::OrderedSet.new
      @nonidempotent_calls = Set.new(call_slug.try(:split, '/')) || Set.new
    end
  end

  def persist_state!
    slug = @entry_points.to_a.join('/') + ':' + @nonidempotent_calls.to_a.join('/')
    store.state = slug
  end

  # Instance methods
  #-----------------------------------------------------------------------------
  def notify(*references)
    notifications = references.inject([]) do |notifications, reference|
      notifications << IdempotentNotifier.new(store, reference).deliver!
      @notifications << reference # TODO: This is only here for specs. Remove.
      notifications
    end
    @steps << [:notification, notifications.compact]
  end

  public
  def already_called_nonidempotent_method?(name)
    @steps << [:idempotent_call, name.to_s]
    @nonidempotent_calls.include?(name.to_s)
  end

  def record_non_idempotent_method_call!(name)
    @nonidempotent_calls << name
  end

  def redirect_to(url_method)
    # I'm still not entirely sure routes belong here.
    # @redirect = Rails.application.routes.url_helpers.send(url_method, *args)
    @redirect = url_method
    @steps << [:redirect, @redirect]
  end

  def redirect?
    @redirect.present?
  end

  # Class methods
  #-----------------------------------------------------------------------------
  def self.decision(method_name, &block)
    assert_instance_method_exists!(method_name)
    aliased_method_name = alias_method_name(method_name)

    yes_block, no_block = DecisionTree::OptionsGrabber.new(&block).options
    fail YesAndNoRequiredError unless yes_block && no_block

    define_method(method_name) do
      if send(aliased_method_name)
        @steps << [method_name, 'YES']
        @proxy.instance_eval(&yes_block)
      else
        @steps << [method_name, 'NO']
        @proxy.instance_eval(&no_block)
      end
    end

    private method_name
  end

  # An entrance point defines a public method on the workflow that allows
  # it to be resumed as the result of some external stimulus - e.g. something
  # in the UI.
  def self.entry(method_name, &block)
    assert_instance_method_exists!(method_name)
    aliased_method_name = alias_method_name(method_name)

    define_method(method_name) do
      @entry_points << method_name.to_s
      @steps << ['Entry Point', method_name.to_s]
      send(aliased_method_name)
      store.start do
        catch :exit do
          @proxy.instance_eval(&block)
        end
        persist_state!
      end
      self
    end
  end

  def self.start(&block)
    define_method(:__start_workflow) { return }
    entry(:__start_workflow, &block)
  end

  private
  def self.assert_instance_method_exists!(method_name)
    fail MethodNotDefinedError, "Method, '#{method_name}', is not defined" unless self.method_defined?(method_name)
  end

  def self.alias_method_name(method_name)
    aliased_method_name = '__' + method_name.to_s
    alias_method aliased_method_name, method_name
    aliased_method_name
  end
end

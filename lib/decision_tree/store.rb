
class DecisionTree::Store
  attr_accessor :state

  def start_workflow(&block)
    yield
  end

  def state!(value)
    @state = value
  end

  # Step storing/fetching
  # Do nothing by default. Implement in application.
  def store_steps!(steps)
  end

  # Do nothing by default. Implement in application.
  def fetch_steps
  end
end

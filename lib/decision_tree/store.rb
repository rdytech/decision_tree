
class DecisionTree::Store
  attr_accessor :state

  def start_workflow(&block)
    yield
  end

  def state!(value)
    @state = value
  end
end

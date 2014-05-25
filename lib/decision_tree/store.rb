
class DecisionTree::Store
  attr_accessor :state

  def start_workflow(&block)
    yield
  end
end


class DecisionTree::Store
  attr_accessor :state

  def start(&block)
    yield
  end
end

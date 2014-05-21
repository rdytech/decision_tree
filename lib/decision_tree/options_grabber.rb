# Utility class to get the yes and no blocks from a decision.
class DecisionTree::OptionsGrabber
  def initialize(&block)
    @yes = @no = nil
    instance_eval(&block)
  end

  def options
    [@yes, @no]
  end

  def yes(&block)
    @yes = block
  end

  def no(&block)
    @no = block
  end
end

class DecisionTree::Store
    attr_accessor :state

    def start
    end

    def state
      @state ||= ''
    end
end

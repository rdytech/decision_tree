# Like a Set, but with ordering guarantee.
class DecisionTree::OrderedSet < Set
    def initialize(enum = nil, &block)
        @hash = ActiveSupport::OrderedHash.new
        super
    end
end
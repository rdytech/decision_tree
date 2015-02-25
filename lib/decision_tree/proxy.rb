# A proxy object so we can intercept calls to non-idempotent methods.
class DecisionTree::Proxy < BasicObject
    def initialize(proxied_object)
        @proxied_object = proxied_object
    end

    def exit(&block)
        @proxied_object.instance_eval(&block)
        throw :exit
        false # This isn't chainable.
    end

    def method_missing(name, *args, &block)
        if name.to_s =~ /!\Z/
            # Method names ending with a bang are assumed to be non-idempotent,
            # and so will only ever be called once in the life-cycle of the change
            # regardless of how many times the workflow is instantiated.
            unless @proxied_object.already_called_nonidempotent_method?(name)
                @proxied_object.send(name, *args, &block)
                @proxied_object.record_non_idempotent_method_call!(name)
            end
            return true
            else
            return @proxied_object.send(name, *args, &block)
        end
    end
end

# Class to represent a single step (currently represented by arrays)
class DecisionTree::Step
  attr_reader :step_type, :step_info
  def initialize(step_type, step_info)
    @step_type = step_type
    @step_info = step_info.is_a?(Symbol) ? step_info.to_s : step_info
  end

  def display
    I18n.t(translation_key, default: default_display)
  end

  private
  def translation_step_key
    @step_type.to_s.downcase.sub(/\s/, '_')
  end

  # What to display if we can't find a translation
  # Accounts for addition of array values in AVETARS
  def default_display
    default_display =
      "#{@step_type.to_s.humanize}".tap do |text|
        if @step_info.respond_to?(:humanize)
          text << " - #{@step_info.humanize}"
        end
      end
  end

  # Where to find a translation for a step
  # Accounts for addition of array values in AVETARS
  def translation_key
    "workflow_steps.#{translation_step_key}".tap do |text|
      if @step_info.respond_to?(:downcase)
        text << ".#{@step_info.downcase}"
      end
    end
  end
end

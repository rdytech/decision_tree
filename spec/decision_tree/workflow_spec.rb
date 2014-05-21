require 'spec_helper'

describe DecisionTree::Workflow do
  class Change
    attr_accessor :workflow_cache

    def workflow_cache
      @workflow_cache ||= ''
    end
  end
  let(:_change) { Change.new }

  describe '.decision' do
    context "when the decision method isn't defined" do
      it 'raises a Workflow::MethodNotDefinedError' do
        expect do
          class TestWorkflow < DecisionTree::Workflow
            decision :this_wont_work do
              yes { exit }
              no { exit }
            end
          end
        end.to raise_error(Workflow::MethodNotDefinedError)
      end
    end

    context "when there isn't both a yes and no block" do
      it 'raises a Workflow::YesAndNoRequiredError' do
        expect do
          class TestWorkflow < DecisionTree::Workflow
            def this_wont_work_either
              true
            end

            decision :this_wont_work_either do
              yes { exit }
            end
          end
        end.to raise_error(Workflow::YesAndNoRequiredError)
      end
    end

    context 'when the decision method returns true' do
      before do
        class TestWorkflow < DecisionTree::Workflow
          def decision_method
            true
          end

          decision :decision_method do
            yes { it_returned_true }
            no { it_returned_false }
          end

          start do
            decision_method
          end
        end
        expect_any_instance_of(TestWorkflow).to receive(:__decision_method).once.and_return(true)
      end

      it 'calls only the yes block' do
        expect_any_instance_of(TestWorkflow).to receive(:it_returned_true).once.and_return(nil)
        expect_any_instance_of(TestWorkflow).not_to receive(:it_returned_false)
        TestWorkflow.new(_change)
      end
    end

    context 'when the decision method returns false' do
      before do
        class TestWorkflow < DecisionTree::Workflow
          def decision_method
            false
          end

          decision :decision_method do
            yes { it_returned_true }
            no { it_returned_false }
          end

          start do
            decision_method
          end
        end
        expect_any_instance_of(TestWorkflow).to receive(:__decision_method).once.and_return(false)
      end

      it 'calls only the no block' do
        expect_any_instance_of(TestWorkflow).not_to receive(:it_returned_true)
        expect_any_instance_of(TestWorkflow).to receive(:it_returned_false).once.and_return(nil)
        TestWorkflow.new(_change)
      end
    end

    describe 'idempotency' do
      before do
        class TestWorkflow < DecisionTree::Workflow
          def always_true
            true # Truth, man.
          end

          decision :always_true do
            yes { non_idempotent_action! }
            no { exit }
          end

          start { always_true }
        end
      end

      context 'when a workflow in instantiated once' do
        it 'calls the non-idempotent method once' do
          expect_any_instance_of(TestWorkflow).to receive(:non_idempotent_action!).once
          TestWorkflow.new(_change)
        end
      end

      context 'when a workflow is instantiated more than once' do
        it 'calls the non-idempotent method only once' do
          expect_any_instance_of(TestWorkflow).to receive(:non_idempotent_action!).once
          TestWorkflow.new(_change)
          TestWorkflow.new(_change)
          TestWorkflow.new(_change)
        end
      end
    end
  end

  describe '.entry' do
    before do
      class TestWorkflow < DecisionTree::Workflow
        def test_entry
        end

        entry(:test_entry) {}
        start {}
      end
    end

    context "when that entry point hasn't been used before" do
      subject { TestWorkflow.new(_change) }

      it 'records it in the workflow_cache' do
        subject.test_entry
        expect(_change.workflow_cache).to match(/test_entry/)
      end

      it 'calls the aliased method' do
        expect_any_instance_of(TestWorkflow).to receive(:__test_entry)
        subject.test_entry
      end
    end

    context 'when the entry point has been used before' do
      before do
        test = TestWorkflow.new(_change)
        test.test_entry
      end

      it 'automatically calls previous entry points' do
        # We call the external method rather than the aliased one.
        expect_any_instance_of(TestWorkflow).to receive(:test_entry).once
        TestWorkflow.new(_change)
      end
    end
  end

  describe '.start' do
    before do
      class TestWorkflow < DecisionTree::Workflow
        def decision_method
          true
        end

        decision :decision_method do
          yes {}
          no {}
        end

        start do
          decision_method
        end
      end
    end

    it 'evaluates the block' do
      expect_any_instance_of(TestWorkflow).to receive(:decision_method).once
      TestWorkflow.new(_change)
    end

    it 'records the start method in the workflow_cache' do
      TestWorkflow.new(_change)
      expect(_change.workflow_cache).to match(/__start_workflow/)
    end
  end
end

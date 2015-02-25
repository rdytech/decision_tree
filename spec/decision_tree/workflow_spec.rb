require 'spec_helper'

describe DecisionTree::Workflow do
  let(:store) { DecisionTree::Store.new }

  describe '.decision' do
    context "when the decision method isn't defined" do
      it 'raises a DecisionTree::Workflow::MethodNotDefinedError' do
        expect do
          class TestWorkflow < DecisionTree::Workflow
            decision :this_wont_work do
              yes { exit }
              no { exit }
            end
          end
        end.to raise_error(DecisionTree::Workflow::MethodNotDefinedError)
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
        end.to raise_error(DecisionTree::Workflow::YesAndNoRequiredError)
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
        TestWorkflow.new(store)
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
        TestWorkflow.new(store)
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
          TestWorkflow.new(store)
        end
      end

      context 'when a workflow is instantiated more than once' do
        it 'calls the non-idempotent method only once' do
          expect_any_instance_of(TestWorkflow).to receive(:non_idempotent_action!).once
          TestWorkflow.new(store)
          TestWorkflow.new(store)
          TestWorkflow.new(store)
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
      subject { TestWorkflow.new(store) }

      it 'records it in the state' do
        subject.test_entry
        expect(store.state).to match(/test_entry/)
      end

      it 'calls the aliased method' do
        expect_any_instance_of(TestWorkflow).to receive(:__test_entry)
        subject.test_entry
      end
    end

    context 'when the entry point has been used before' do
      before do
        test = TestWorkflow.new(store)
        test.test_entry
      end

      it 'automatically calls previous entry points' do
        # We call the external method rather than the aliased one.
        expect_any_instance_of(TestWorkflow).to receive(:test_entry).once
        TestWorkflow.new(store)
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
      TestWorkflow.new(store)
    end

    it 'records the start method in the state' do
      TestWorkflow.new(store)
      expect(store.state).to match(/__start_workflow/)
    end
  end

  describe '.initialize' do
    before do
      class TestWorkflow < DecisionTree::Workflow
      end

      allow_any_instance_of(TestWorkflow).to receive(:finished?) { finished }
    end

    subject { TestWorkflow.new(store) }

    context 'when workflow not previously completed' do
      let(:finished) { false }
      specify 'executes the workflow' do
        expect_any_instance_of(TestWorkflow).to receive(:execute_workflow)
        subject
      end
    end

    context 'when workflow previously completed' do
      let(:finished) { true }

      specify 'does not execute the workflow' do
        expect_any_instance_of(TestWorkflow).to_not receive(:execute_workflow)
        subject
      end

      specify 'fetches previously executed steps from the store' do
        expect(store).to receive(:fetch_steps)
        subject
      end
    end
  end

  describe 'finish!' do
    subject { workflow.instance_variable_get(:@nonidempotent_calls) }
    let(:finish!) { workflow.finish! }

    before do
      class TestWorkflow < DecisionTree::Workflow
        start {}
      end
    end

    let(:workflow) { TestWorkflow.new(store) }

    specify 'records the finish call' do
      finish!
      expect(subject).to include('finish!')
    end
  end

  describe 'calling finish!' do
    let(:workflow) { TestWorkflow.new(store) }

    context 'from a start block' do

      before do
        class TestWorkflow < DecisionTree::Workflow
          start { finish! }
        end
      end

      specify 'calls finish! on the workflow' do
        expect_any_instance_of(TestWorkflow).to receive(:finish!)
        workflow
      end
    end

    context 'from a decision block' do
      before do
        class TestWorkflow < DecisionTree::Workflow
          def decision_method
            true
          end

          start { decision_method }

          decision :decision_method do
            yes { finish! }
            no  {  }
          end
        end
      end

      specify 'calls finish! on the workflow' do
        expect_any_instance_of(TestWorkflow).to receive(:finish!)
        workflow
      end
    end
  end

  describe '.finished?' do
    subject { workflow.finished? }

    before do
      class TestWorkflow < DecisionTree::Workflow
        start {}
      end
    end

    let(:workflow) { TestWorkflow.new(store) }

    context 'when workflow has been finished' do
      before { workflow.finish! }
      specify { expect(subject).to be_truthy }
    end

    context 'when workflow has not been finished' do
      specify { expect(subject).to be_falsey }
    end
  end
end

require 'spec_helper'

describe DecisionTree::Step do
  let(:step) { described_class.new(step_type, step_info) }

  let(:translations) do
    {
      workflow_steps:
      {
        reviewed_by_etd?:
        {
          yes: 'ETD has reviewed the provided evidence',
          no: 'Waiting on ETD to review the provided evidence'
        },
        entry_point:
        {
          reviewed_by_etd!: 'ETD has reviewed the provided evidence'
        },
        idempotent_call:
        {
          mark_for_review!: 'Waiting on ETD to review evidence'
        }
      }
    }
  end

  before do
    I18n.backend.store_translations(:en, translations)
  end

  describe 'display' do
    subject { step.display }

    context 'when translation exists' do
      context 'for a standard step' do
        let(:step_type) { :reviewed_by_etd? }
        context 'that evaluates to false' do
          let(:step_info) { 'NO' }
          it { should eql 'Waiting on ETD to review the provided evidence' }
        end

        context 'that evaluates to true' do
          let(:step_info) { 'YES' }
          it { should eql 'ETD has reviewed the provided evidence' }
        end
      end

      context 'for an entry point' do
        let(:step_type) { 'Entry Point' }
        let(:step_info) { :reviewed_by_etd! }

        it { should eql 'ETD has reviewed the provided evidence' }
      end

      context 'for an idempotent call' do
        let(:step_type) { :idempotent_call }
        let(:step_info) { :mark_for_review! }

        it { should eql 'Waiting on ETD to review evidence' }
      end
    end

    context 'when translation does not exist' do
      let(:step_type) { :is_this_a_question? }
      let(:step_info) { 'YES' }

      it 'falls back to question/answer format' do
        expect(subject).to eql 'Is this a question? - Yes'
      end
    end

    context 'when step info is an array' do
      let(:notification) { double('notification') }
      let(:step_type) { :notification }
      let(:step_info) { [notification] }

      it { should eql 'Notification' }
    end
  end
end

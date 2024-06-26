# frozen_string_literal: true

RSpec.describe_current do
  subject(:callback) do
    described_class.new(
      subscription_group_id,
      consumer_group_id,
      client_name
    )
  end

  let(:subscription_group_id) { SecureRandom.hex(6) }
  let(:consumer_group_id) { SecureRandom.hex(6) }
  let(:client_name) { SecureRandom.hex(6) }
  let(:monitor) { ::Karafka.monitor }
  let(:error) { ::Rdkafka::RdkafkaError.new(1, []) }

  describe '#call' do
    let(:changed) { [] }

    before do
      monitor.subscribe('error.occurred') do |event|
        changed << event[:error]
      end

      callback.call(client_name, error)
    end

    context 'when emitted error refer different producer' do
      subject(:callback) do
        described_class.new(subscription_group_id, consumer_group_id, 'other')
      end

      it 'expect not to emit them' do
        expect(changed).to be_empty
      end
    end

    context 'when emitted error refer to expected producer' do
      it 'expects to emit them' do
        expect(changed).to eq([error])
      end
    end
  end

  describe 'emitted event data format' do
    let(:changed) { [] }
    let(:event) { changed.first }

    before do
      monitor.subscribe('error.occurred') do |stat|
        changed << stat
      end

      callback.call(client_name, error)
    end

    it { expect(event.id).to eq('error.occurred') }
    it { expect(event[:subscription_group_id]).to eq(subscription_group_id) }
    it { expect(event[:consumer_group_id]).to eq(consumer_group_id) }
    it { expect(event[:error]).to eq(error) }
  end

  context 'when error handling handler contains error' do
    let(:tracked_errors) { [] }

    before do
      monitor.subscribe('error.occurred') do |event|
        next unless event[:type] == 'librdkafka.error'

        raise
      end

      local_errors = tracked_errors

      monitor.subscribe('error.occurred') do |event|
        local_errors << event
      end
    end

    it 'expect to contain in, notify and continue as we do not want to crash rdkafka' do
      expect { callback.call(client_name, error) }.not_to raise_error
      expect(tracked_errors.size).to eq(1)
      expect(tracked_errors.first[:type]).to eq('callbacks.error.error')
    end
  end
end

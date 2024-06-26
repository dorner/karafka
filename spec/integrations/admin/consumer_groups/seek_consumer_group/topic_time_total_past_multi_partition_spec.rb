# frozen_string_literal: true

# We should be able to move the offset way beyond in time for all partitions at once

setup_karafka

class Consumer < Karafka::BaseConsumer
  def consume
    messages.each do |message|
      DT[partition] << message.offset
    end
  end
end

draw_routes do
  consumer_group DT.consumer_group do
    topic DT.topic do
      consumer Consumer
      config(partitions: 3)
    end
  end
end

10.times do
  sleep(0.1)

  3.times do |partition|
    produce(DT.topic, '', partition: partition)
  end
end

start_karafka_and_wait_until do
  DT[0].size >= 10 &&
    DT[1].size >= 10 &&
    DT[2].size >= 10
end

Karafka::Admin.seek_consumer_group(
  DT.consumer_group,
  {
    DT.topic => {
      0 => Time.now - 60 * 60,
      1 => Time.now - 60 * 60,
      2 => Time.now - 60 * 60
    }
  }
)

results = Karafka::Admin.read_lags_with_offsets
cg = DT.consumer_group
part_results = results.fetch(cg).fetch(DT.topic)

assert_equal 0, part_results[0][:offset]
assert_equal 0, part_results[1][:offset]
assert_equal 0, part_results[2][:offset]

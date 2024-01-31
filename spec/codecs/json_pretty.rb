require "logstash/devutils/rspec/spec_helper"
require "logstash/codecs/json_pretty"
require "logstash/event"
require "json"

describe LogStash::Codecs::JsonPretty do

  subject { LogStash::Codecs::JsonPretty.new }

  context "#encode" do
    let(:event) { LogStash::Event.new({"what" => "ok", "who" => 2}) }

    before(:each) { subject.register }

    it "should print beautiful hashes" do
      on_event = lambda { |e, d| expect(d.chomp).to eq(JSON.pretty_generate(event.to_hash, { indent: '    ' })) }

      subject.on_event(&on_event)
      expect(on_event).to receive(:call).once.and_call_original

      subject.encode(event)
    end
  end

  context "#decode" do
    it "should not be implemented" do
      expect { subject.decode("data") }.to raise_error("Not implemented")
    end
  end
end


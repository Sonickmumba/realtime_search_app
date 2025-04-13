require 'rails_helper'

RSpec.describe FinalizeSearchJob, type: :job do
  let(:ip) { "111.223.33.72" }
  let(:query) { "Sonick" }
  let(:token) { Time.now.to_f }

  before do
    $redis.set("search_buffer:#{ip}", query, ex: 10)
    $redis.set("search_token:#{ip}", token, ex: 10)
  end

  it "saves new query" do
    expect {
      described_class.new.perform(ip, token)
      
    }.to change(SearchLog, :count).by(1)

    log = SearchLog.last
    expect(log.query).to eq("Sonick")
    expect(log.ip_address).to eq(ip)
  end

  it "skips outdated token" do
    $redis.set("search_token:#{ip}", token + 1, ex: 10)

    expect {
      described_class.new.perform(ip, token)
    }.not_to change(SearchLog, :count)
  end

  it "skips if duplicate within 5 min" do
    SearchLog.create!(query: query, ip_address: ip, created_at: 5.minutes.ago)

    expect {
      described_class.new.perform(ip, token)
    }.not_to change(SearchLog, :count)
  end
end

require 'rails_helper'

RSpec.describe "SearchInputs", type: :request do
  let(:ip) { "153.496.709.000" }

  before do
    allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(ip)
    $redis = MockRedis.new
  end

  it "saves query and enqueues job" do
    expect {
      post "/search_inputs",
           params: { query: "Sonick" }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }
    }.to have_enqueued_job(FinalizeSearchJob).with(ip, kind_of(Float))
  end

  it "rejects empty query" do
    post "/search_inputs",
         params: { query: " " }.to_json,
         headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:bad_request)
    expect(FinalizeSearchJob).not_to have_been_enqueued
  end
end


RSpec.describe "SearchInputs", type: :request do
  describe "Search input saving and finalization" do
    let(:ip1) { "1.1.1.1" }
    let(:ip2) { "2.2.2.2" }
    let(:token) { 1234.0 }

    before do
      allow(FinalizeSearchJob).to receive(:set).and_return(FinalizeSearchJob)
      allow(FinalizeSearchJob).to receive(:perform_later)
      SearchLog.delete_all
      $redis.flushdb if $redis.respond_to?(:flushdb)
    end

    it "only saves the final complete search after debounce" do
      ["What", "What is", "What is a", "What is a good car"].each do |q|
        post "/search_inputs", params: { query: q }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" },
             env: { "REMOTE_ADDR" => ip1 }
      end

      ["How", "How is", "How is emil hajric", "How is emil hajric doing"].each do |q|
        post "/search_inputs", params: { query: q }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" },
             env: { "REMOTE_ADDR" => ip2 }
      end

      $redis.set("search_buffer:#{ip1}", "What is a good car")
      $redis.set("search_token:#{ip1}", token.to_s)

      $redis.set("search_buffer:#{ip2}", "How is emil hajric doing")
      $redis.set("search_token:#{ip2}", token.to_s)

      FinalizeSearchJob.perform_now(ip1, token)
      FinalizeSearchJob.perform_now(ip2, token)

      expect(SearchLog.last(2).map(&:query)).to contain_exactly(
        "What is a good car",
        "How is emil hajric doing"
      )
    end
  end
end


describe "SearchInputs" do
  let(:ip1) { "127.0.0.1" }
  let(:ip2) { "127.0.0.2" }
  let(:token) { 1234.0 }

  before do
    allow($redis).to receive(:get).with("search_buffer:#{ip1}").and_return("What is a good car")
    allow($redis).to receive(:get).with("search_token:#{ip1}").and_return(token.to_s)

    allow($redis).to receive(:get).with("search_buffer:#{ip2}").and_return("How is emil hajric doing")
    allow($redis).to receive(:get).with("search_token:#{ip2}").and_return(token.to_s)

    allow($redis).to receive(:del)
  end

  it "Search input buffering and finalization only saves the final complete search after debounce" do
    FinalizeSearchJob.perform_now(ip1, token)
    FinalizeSearchJob.perform_now(ip2, token)

    expect(SearchLog.last(2).map(&:query)).to contain_exactly(
      "What is a good car",
      "How is emil hajric doing"
    )
  end
end



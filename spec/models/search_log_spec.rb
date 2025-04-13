require 'rails_helper'

RSpec.describe SearchLog, type: :model do
  it "is valid with a query and IP address" do
    log = SearchLog.new(query: "Sonick", ip_address: "127.1.5.1")
    expect(log).to be_valid
  end

  it "is invalid without a query" do
    log = SearchLog.new(ip_address: "127.1.5.1")
    expect(log).not_to be_valid
  end

  it "is invalid without an IP address" do
    log = SearchLog.new(query: "Sonick")
    expect(log).not_to be_valid
  end
end

class SearchLog < ApplicationRecord
  validates :query, presence: true
  validates :ip_address, presence: true
end

module Api
  class AnalyticsController < ApplicationController

    def trending
      recent_logs = SearchLog.where("created_at >= ?", 24.hours.ago)

      grouped_logs = recent_logs
        .select(:ip_address, :query)
        .group(:query, :ip_address)
        .count('*')

      trend_counts = Hash.new(0)
      grouped_logs.each do |(query, _ip), count|
        trend_counts[query] += count
      end

      sorted_logs = trend_counts.sort_by { |query, count| -count }

      render json: sorted_logs.map { |query, count| { query: query, count: count } }
    end
  end
end

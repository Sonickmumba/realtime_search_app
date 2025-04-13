class FinalizeSearchJob < ApplicationJob
  queue_as :default

  def perform(ip, token)
    save_key = "search_buffer:#{ip}"
    token_key = "search_token:#{ip}"

    query = $redis.get(save_key)&.strip
    current_token = $redis.get(token_key)&.to_f

    if current_token != token
      return
    end

    return unless query.present?

    recent = SearchLog.where(ip_address: ip)
                      .where("created_at >= ?", 10.minutes.ago)
                      .order(created_at: :desc)
                      .limit(1)
                      .first

    if recent&.query != query
      SearchLog.create!(query: query, ip_address: ip)
    end

    $redis.del(save_key)
    $redis.del(token_key)
  end
end




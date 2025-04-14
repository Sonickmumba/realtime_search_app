class SearchInputsController < ApplicationController
  def create
    input_query = params[:query].to_s.strip
    user_ip = request.remote_ip

    if input_query.blank?
      head :bad_request
      return
    end

    token = Time.now.to_f
    save_key = "search_buffer:#{user_ip}"
    token_key = "search_token:#{user_ip}"

    $redis.set(save_key, input_query, ex: 5)
    $redis.set(token_key, token, ex: 5)

    FinalizeSearchJob.set(wait: 3.seconds).perform_later(user_ip, token)

    render json: {status: "Saved", query: input_query}, status: :ok
  end
end

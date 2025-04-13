Rails.application.routes.draw do
  post "/search_inputs", to: "search_inputs#create"

  namespace :api do
    get 'analytics/trending', to: 'analytics#trending'
  end
end

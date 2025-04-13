Rails.application.routes.draw do
  post "/search_inputs", to: "search_inputs#create"
  # Defines the root path route ("/")
  # root "posts#index"
end

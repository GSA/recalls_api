RecallsApi::Application.routes.draw do
  root to: 'api/v1/recalls#index', format: :json

  scope module: 'api/v1',
        constraints: ApiConstraint.new(version: 1, default: true),
        defaults: { format: :json } do
    get '/' => 'recalls#index', format: false
    get '/recent(.json)' => 'recalls#index', format: false
    get '/search(.json)' => 'recalls#search', format: false
  end

  scope module: 'api/v1', defaults: { format: :rss } do
    get '/recent.rss' => 'recalls#index', format: false
  end
end

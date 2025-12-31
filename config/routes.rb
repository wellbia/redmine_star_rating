# frozen_string_literal: true

RedmineApp::Application.routes.draw do
  post 'rateable_ratings', to: 'rateable_ratings#create'
end

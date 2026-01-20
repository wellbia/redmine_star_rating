# frozen_string_literal: true

require_relative 'lib/redmine_star_rating/hooks'
require_relative 'lib/redmine_star_rating/issue_patch'
require_relative 'lib/redmine_star_rating/issue_query_patch'

Redmine::Plugin.register :redmine_star_rating do
  name 'Redmine Star Rating'
  author 'wellbia'
  description 'A polymorphic star rating plugin for Issues and Journals (comments)'
  version '1.0.0'
  url 'https://github.com/wellbia/redmine_star_rating'
  author_url 'https://github.com/wellbia'

  requires_redmine version_or_higher: '5.0.0'

  # Project module - 프로젝트별로 별점 기능 활성화/비활성화 가능
  project_module :star_rating do
    permission :rate_rateables, {
      rateable_ratings: [:create]
    }, public: false
  end

  # Plugin settings
  settings default: {
    'enable_issue_rating' => true,
    'enable_journal_rating' => true,
    'allow_self_rating' => false
  }, partial: 'settings/star_rating_settings'
end

# frozen_string_literal: true

require_relative 'lib/redmine_star_rating/hooks'

Redmine::Plugin.register :redmine_star_rating do
  name 'Redmine Star Rating'
  author 'Your Name'
  description 'A polymorphic star rating plugin for Issues and Journals (comments)'
  version '1.0.0'
  url 'https://github.com/your-repo/redmine_star_rating'
  author_url 'https://github.com/your-name'

  requires_redmine version_or_higher: '5.0.0'

  # Permission
  permission :rate_rateables, {
    rateable_ratings: [:create]
  }, public: false

  # Plugin settings
  settings default: {
    'enable_issue_rating' => true,
    'enable_journal_rating' => true,
    'allow_self_rating' => false
  }, partial: 'settings/star_rating_settings'
end

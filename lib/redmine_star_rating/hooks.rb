# frozen_string_literal: true

module RedmineStarRating
  class Hooks < Redmine::Hook::ViewListener
    # Include assets in the header
    def view_layouts_base_html_head(context = {})
      stylesheet_link_tag('rateable_ratings', plugin: 'redmine_star_rating') +
        javascript_include_tag('rateable_ratings', plugin: 'redmine_star_rating')
    end

    # Insert rating UI below issue description
    render_on :view_issues_show_description_bottom, partial: 'rateable_ratings/stars_issue'

    # Insert rating UI for each journal (below the journal content)
    render_on :view_issues_history_journal_bottom, partial: 'rateable_ratings/stars_journal'
  end
end

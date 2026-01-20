# frozen_string_literal: true

module RedmineStarRating
  module IssueQueryPatch
    def self.included(base)
      base.class_eval do
        # Add the star rating filter
        add_available_filter 'star_rating_avg',
                             type: :float,
                             name: I18n.t(:label_star_rating_avg, default: 'Average Star Rating')
      end
    end

    # Override sql_for_field to handle star_rating_avg filter
    def sql_for_star_rating_avg_field(field, operator, value)
      # Subquery to calculate average rating for each issue
      avg_subquery = <<~SQL.squish
        (SELECT AVG(rr.score)
         FROM #{RateableRating.table_name} rr
         WHERE rr.rateable_type = 'Issue'
         AND rr.rateable_id = #{Issue.table_name}.id)
      SQL

      case operator
      when '='
        # Equal to value
        "#{avg_subquery} = #{value.first.to_f}"
      when '>='
        # Greater than or equal
        "#{avg_subquery} >= #{value.first.to_f}"
      when '<='
        # Less than or equal
        "#{avg_subquery} <= #{value.first.to_f}"
      when '><'
        # Between (value should have 2 elements)
        min_val = value[0].to_f
        max_val = value[1].to_f
        "#{avg_subquery} BETWEEN #{min_val} AND #{max_val}"
      when '*'
        # Has rating (not null, at least one rating exists)
        "#{avg_subquery} IS NOT NULL"
      when '!*'
        # No rating
        "#{avg_subquery} IS NULL"
      else
        # Default: greater than or equal
        "#{avg_subquery} >= #{value.first.to_f}"
      end
    end
  end
end

# Apply the patch
Rails.application.config.after_initialize do
  unless IssueQuery.included_modules.include?(RedmineStarRating::IssueQueryPatch)
    IssueQuery.include(RedmineStarRating::IssueQueryPatch)
  end
end

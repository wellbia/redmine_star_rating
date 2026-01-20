# frozen_string_literal: true

module RedmineStarRating
  module IssueQueryPatch
    def self.included(base)
      base.class_eval do
        alias_method :initialize_available_filters_without_star_rating, :initialize_available_filters
        alias_method :initialize_available_filters, :initialize_available_filters_with_star_rating
      end
    end

    def initialize_available_filters_with_star_rating
      initialize_available_filters_without_star_rating

      # Filter 1: Issue ratings only
      add_available_filter 'star_rating_issue_avg',
                           type: :float,
                           name: I18n.t(:label_star_rating_issue_avg, default: 'Issue Star Rating')

      # Filter 2: Journal (comment) ratings only
      add_available_filter 'star_rating_journal_avg',
                           type: :float,
                           name: I18n.t(:label_star_rating_journal_avg, default: 'Comment Star Rating')

      # Filter 3: All ratings combined (issue + journals)
      add_available_filter 'star_rating_all_avg',
                           type: :float,
                           name: I18n.t(:label_star_rating_all_avg, default: 'Total Star Rating')
    end

    # Filter 1: Issue ratings only
    def sql_for_star_rating_issue_avg_field(field, operator, value)
      avg_subquery = <<~SQL.squish
        (SELECT AVG(rr.score)
         FROM #{RateableRating.table_name} rr
         WHERE rr.rateable_type = 'Issue'
         AND rr.rateable_id = #{Issue.table_name}.id)
      SQL

      build_rating_sql(avg_subquery, operator, value)
    end

    # Filter 2: Journal (comment) ratings only
    def sql_for_star_rating_journal_avg_field(field, operator, value)
      avg_subquery = <<~SQL.squish
        (SELECT AVG(rr.score)
         FROM #{RateableRating.table_name} rr
         WHERE rr.rateable_type = 'Journal'
         AND rr.rateable_id IN (
           SELECT j.id FROM #{Journal.table_name} j
           WHERE j.journalized_type = 'Issue'
           AND j.journalized_id = #{Issue.table_name}.id
         ))
      SQL

      build_rating_sql(avg_subquery, operator, value)
    end

    # Filter 3: All ratings combined (issue + journals) - uses MIN (lowest rating)
    def sql_for_star_rating_all_avg_field(field, operator, value)
      min_subquery = <<~SQL.squish
        (SELECT MIN(rr.score)
         FROM #{RateableRating.table_name} rr
         WHERE (rr.rateable_type = 'Issue' AND rr.rateable_id = #{Issue.table_name}.id)
            OR (rr.rateable_type = 'Journal' AND rr.rateable_id IN (
                  SELECT j.id FROM #{Journal.table_name} j
                  WHERE j.journalized_type = 'Issue'
                  AND j.journalized_id = #{Issue.table_name}.id
                )))
      SQL

      build_rating_sql(min_subquery, operator, value)
    end

    private

    def build_rating_sql(avg_subquery, operator, value)
      case operator
      when '='
        "#{avg_subquery} = #{value.first.to_f}"
      when '>='
        "#{avg_subquery} >= #{value.first.to_f}"
      when '<='
        "#{avg_subquery} <= #{value.first.to_f}"
      when '><'
        min_val = value[0].to_f
        max_val = value[1].to_f
        "#{avg_subquery} BETWEEN #{min_val} AND #{max_val}"
      when '*'
        "#{avg_subquery} IS NOT NULL"
      when '!*'
        "#{avg_subquery} IS NULL"
      else
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

# frozen_string_literal: true

module RedmineStarRating
  module IssuePatch
    def self.included(base)
      base.class_eval do
        # Add custom method for API
        def rateable_avg
          @rateable_avg ||= RateableRating.stats_for('Issue', id)
        end
      end
    end
  end

  module JournalPatch
    def self.included(base)
      base.class_eval do
        # Add custom method for API
        def rateable_avg
          @rateable_avg ||= RateableRating.stats_for('Journal', id)
        end
      end
    end
  end

  module IssuesControllerPatch
    def self.included(base)
      base.class_eval do
        after_action :add_rateable_data_to_api, only: [:show]

        private

        def add_rateable_data_to_api
          return unless request.format.json? || request.format.xml?
          return unless @issue

          # Add rating data to issue
          @issue.define_singleton_method(:rateable_avg) do
            @rateable_avg ||= RateableRating.stats_for('Issue', id)
          end

          # Add rating data to journals if included
          if @journals && @journals.any?
            @journals.each do |journal|
              journal.define_singleton_method(:rateable_avg) do
                @rateable_avg ||= RateableRating.stats_for('Journal', id)
              end
            end
          end
        end
      end
    end
  end
end

# Apply patches
Rails.application.config.after_initialize do
  unless Issue.included_modules.include?(RedmineStarRating::IssuePatch)
    Issue.include(RedmineStarRating::IssuePatch)
  end
  unless Journal.included_modules.include?(RedmineStarRating::JournalPatch)
    Journal.include(RedmineStarRating::JournalPatch)
  end
  unless IssuesController.included_modules.include?(RedmineStarRating::IssuesControllerPatch)
    IssuesController.include(RedmineStarRating::IssuesControllerPatch)
  end
end

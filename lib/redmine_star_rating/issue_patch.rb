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
          return unless @issue
          return unless response.successful?

          if request.format.json?
            inject_rateable_json
          elsif request.format.xml?
            inject_rateable_xml
          end
        rescue => e
          Rails.logger.error("redmine_star_rating: failed to inject rateable_avg: #{e.class}: #{e.message}")
        end

        def inject_rateable_json
          body = response.body
          return if body.blank?

          data = JSON.parse(body)
          issue_data = data['issue']
          return unless issue_data

          issue_stats = RateableRating.stats_for('Issue', @issue.id)
          issue_data['rateable_avg'] = { 'avg' => issue_stats[:avg], 'count' => issue_stats[:count] }

          if issue_data['journals'].is_a?(Array)
            issue_data['journals'].each do |journal|
              jid = journal['id']
              next unless jid
              jstats = RateableRating.stats_for('Journal', jid)
              journal['rateable_avg'] = { 'avg' => jstats[:avg], 'count' => jstats[:count] }
            end
          end

          response.body = data.to_json
        end

        def inject_rateable_xml
          require 'nokogiri'
          body = response.body
          return if body.blank?

          doc = Nokogiri::XML(body)
          issue_node = doc.at_xpath('/issue')
          return unless issue_node

          issue_stats = RateableRating.stats_for('Issue', @issue.id)
          append_rateable_xml(doc, issue_node, issue_stats)

          doc.xpath('/issue/journals/journal').each do |journal_node|
            jid = journal_node['id'].to_i
            next if jid.zero?
            jstats = RateableRating.stats_for('Journal', jid)
            append_rateable_xml(doc, journal_node, jstats)
          end

          response.body = doc.root.to_xml
        end

        def append_rateable_xml(doc, parent, stats)
          node = doc.create_element('rateable_avg')
          node.add_child(doc.create_element('avg', stats[:avg].to_s))
          node.add_child(doc.create_element('count', stats[:count].to_s))
          parent.add_child(node)
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

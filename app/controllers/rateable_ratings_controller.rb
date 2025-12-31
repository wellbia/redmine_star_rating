# frozen_string_literal: true

class RateableRatingsController < ApplicationController
  before_action :require_login
  before_action :authorize_global, only: [:create]
  before_action :set_rateable, only: [:create]
  before_action :check_self_rating, only: [:create]

  accept_api_auth :create

  def create
    score = params[:score].to_i
    unless (1..5).include?(score)
      render json: { error: 'Score must be between 1 and 5' }, status: :bad_request
      return
    end

    rating = RateableRating.find_or_initialize_for(
      params[:rateable_type],
      params[:rateable_id],
      User.current
    )
    rating.score = score

    if rating.save
      stats = RateableRating.stats_for(params[:rateable_type], params[:rateable_id])
      render json: {
        avg: stats[:avg],
        count: stats[:count],
        my_score: rating.score
      }
    else
      render json: { error: rating.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def set_rateable
    @rateable_type = params[:rateable_type]
    @rateable_id = params[:rateable_id].to_i

    unless %w[Issue Journal].include?(@rateable_type)
      render json: { error: 'Invalid rateable type' }, status: :bad_request
      return
    end

    # Check if rating is enabled for this type
    settings = Setting.plugin_redmine_star_rating
    case @rateable_type
    when 'Issue'
      unless settings['enable_issue_rating']
        render json: { error: 'Issue rating is disabled' }, status: :forbidden
        return
      end
      @rateable = Issue.find_by(id: @rateable_id)
    when 'Journal'
      unless settings['enable_journal_rating']
        render json: { error: 'Journal rating is disabled' }, status: :forbidden
        return
      end
      @rateable = Journal.find_by(id: @rateable_id)
    end

    unless @rateable
      render json: { error: 'Rateable not found' }, status: :not_found
    end
  end

  def check_self_rating
    return if @rateable.nil?

    settings = Setting.plugin_redmine_star_rating
    allow_self = settings['allow_self_rating']

    author = case @rateable_type
             when 'Issue'
               @rateable.author
             when 'Journal'
               @rateable.user
             end

    if !allow_self && author == User.current
      render json: { error: 'You cannot rate your own content' }, status: :forbidden
    end
  end

  def authorize_global
    unless User.current.allowed_to_globally?(:rate_rateables)
      render json: { error: 'Permission denied' }, status: :forbidden
    end
  end
end

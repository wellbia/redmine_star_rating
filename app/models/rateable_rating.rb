# frozen_string_literal: true

class RateableRating < ActiveRecord::Base
  self.table_name = 'rateable_ratings'

  belongs_to :rateable, polymorphic: true
  belongs_to :user

  validates :score, presence: true, inclusion: { in: 1..5 }
  validates :rateable_type, presence: true
  validates :rateable_id, presence: true
  validates :user_id, presence: true, uniqueness: { scope: [:rateable_type, :rateable_id], message: 'has already rated this item' }

  scope :for_rateable, ->(type, id) { where(rateable_type: type, rateable_id: id) }
  scope :by_user, ->(user) { where(user_id: user.id) }

  # Calculate average and count for a rateable object
  def self.stats_for(rateable_type, rateable_id)
    ratings = for_rateable(rateable_type, rateable_id)
    count = ratings.count
    avg = count > 0 ? ratings.average(:score).to_f.round(1) : 0.0
    { avg: avg, count: count }
  end

  # Find or initialize rating for user
  def self.find_or_initialize_for(rateable_type, rateable_id, user)
    find_or_initialize_by(
      rateable_type: rateable_type,
      rateable_id: rateable_id,
      user_id: user.id
    )
  end
end

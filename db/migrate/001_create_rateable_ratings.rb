# frozen_string_literal: true

class CreateRateableRatings < ActiveRecord::Migration[5.2]
  def change
    create_table :rateable_ratings do |t|
      t.string :rateable_type, null: false
      t.integer :rateable_id, null: false
      t.integer :user_id, null: false
      t.integer :score, null: false

      t.timestamps null: false
    end

    add_index :rateable_ratings, [:rateable_type, :rateable_id, :user_id],
              unique: true,
              name: 'index_rateable_ratings_uniqueness'
    add_index :rateable_ratings, [:rateable_type, :rateable_id],
              name: 'index_rateable_ratings_on_rateable'
    add_index :rateable_ratings, :user_id
  end
end

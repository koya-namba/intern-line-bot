class User < ApplicationRecord
  validates :line_user_id, uniqueness: true, presence: true
  has_many :group_users
  has_many :groups, through: :group_users
end

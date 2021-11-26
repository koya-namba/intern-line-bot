class GroupUser < ApplicationRecord
  validates :group_id, presence: true, uniqueness: {scope: :user_id}
  validates :user_id, presence: true
  belongs_to :user
  belongs_to :group
end

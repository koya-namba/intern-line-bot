class CreateGroupUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :group_users do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :group, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
    add_index :group_users, [:group_id, :user_id], unique: true
  end
end

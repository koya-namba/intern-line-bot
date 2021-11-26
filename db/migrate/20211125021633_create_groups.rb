class CreateGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :groups do |t|
      t.string :line_group_id, null: false
      t.string :name, null: false
      t.timestamps
    end
  end
end

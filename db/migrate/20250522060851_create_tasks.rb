class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.references :employee, null: false, foreign_key: true
      t.string :status
      t.string :category
      t.text :detail
      t.datetime :due

      t.timestamps
    end
  end
end

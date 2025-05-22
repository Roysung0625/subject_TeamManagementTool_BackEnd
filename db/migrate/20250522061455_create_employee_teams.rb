class CreateEmployeeTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_teams do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.datetime :joined_at

      t.timestamps
    end
  end
end

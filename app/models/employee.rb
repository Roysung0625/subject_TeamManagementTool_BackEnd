class Employee < ApplicationRecord
  # N:M
  has_many :employee_teams, dependent: :destroy
  has_many :teams, through: :employee_teams

  # Task 1:N
  has_many :tasks, dependent: :destroy
end

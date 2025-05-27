class Team < ApplicationRecord
  # N:M
  has_many :employee_teams, dependent: :destroy
  has_many :employees, through: :employee_teams

  # 필수 값 검증
  validates :name, presence: true
end
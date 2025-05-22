class EmployeeTeam < ApplicationRecord
  # JoinColumn
  belongs_to :employee
  belongs_to :team
end

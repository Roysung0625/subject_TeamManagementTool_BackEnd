
module Response
  module Teams
    TeamSummaryDto = Struct.new(
      :id,
      :name,
      :members
    ) do

      def self.from_team(team_model)
        member_dtos = team_model.employees.map do |employee_model|
          Response::Teams::EmployeeSummaryDto.from_employee(employee_model)
        end
        new(
          team_model[:id],
          team_model[:name],
          member_dtos
        )
      end
      def as_json(options = {})
        to_h.as_json(options)
      end
    end
  end
end
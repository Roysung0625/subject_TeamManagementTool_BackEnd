
module Response
  module Teams
    EmployeeSummaryDto = Struct.new(
      :id,
      :name,
      :role
    ) do
      def self.from_employee(employee_model)
        new(
          employee_model[:id],
          employee_model[:name],
          employee_model[:role]
        )
      end

      def as_json(options = {})
        to_h.as_json(options)
      end
    end
  end
end
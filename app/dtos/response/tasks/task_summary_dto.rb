
module Response
  module Tasks
    TaskSummaryDto = Struct.new(
      :id,
      :title,
      :status,
      :category,
      :detail,
      :due_at,
      :employee_id
    ) do
      def self.from_task(task_model)
        new(
          task_model.id,
          task_model.title,
          task_model.status,
          task_model.category,
          task_model.detail,
          task_model.due,
          #&呼び出しでnilならmethod呼び出しの代わりにnil return
          task_model.employee&.id
        )
      end

      def as_json(options = {})
        to_h.as_json(options)
      end
    end
  end
end
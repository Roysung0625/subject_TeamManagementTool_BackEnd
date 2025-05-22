class Task < ApplicationRecord
  # Task는 반드시 Employee에 속함
  belongs_to :employee

  enum status: { pending: "pending", in_progress: "in_progress", done: "done" }

  # 필수 값 검증 예시
  # validates :status, :category, :detail, :due, presence: true
end

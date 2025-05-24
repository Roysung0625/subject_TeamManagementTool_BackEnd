# frozen_string_literal: true

class TaskSerializer < ActiveModel::Serializer
  attributes :id, :title, :status, :category, :detail, :due, :created_at, :updated_at

  belongs_to :employee
end
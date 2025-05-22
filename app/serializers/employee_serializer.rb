# frozen_string_literal: true

class EmployeeSerializer < ActiveModel::Serializer
  attributes :id, :name, :role, :created_at, :updated_at

  has_many :teams
  has_many :tasks
end
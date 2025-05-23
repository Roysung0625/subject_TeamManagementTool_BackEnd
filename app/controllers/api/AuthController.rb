# frozen_string_literal: true

module Api
  class AuthController < ApplicationController
    include Authenticatable

    before_action :authenticate_request!, only: %i[logout]

    # POST /api/auth/login
    def login
      employee = Employee.find_by(employee_id: employee_params[:employee_id])
      #&.(safe navigation)を使うと、employeeがnilの場合でも、NoMethod Errorの代わりにnilをreturn
      #authenticate methodはApplication Recordから継承
      if employee&.authenticate(params[:password])
        token = JsonWebToken.encode(employee_id: employee.id)
        render json: { token: token, employee: EmployeeSerializer.new(employee) }
      else
        render json: { error: 'Invalid credentials' }, status: :unauthorized
      end
    end

    # POST /api/auth/register
    def register
      employee = Employee.create!(employee_params)
      token = JsonWebToken.encode(employee_id: employee.id)
      render json: { token: token, employee: EmployeeSerializer.new(employee) }, status: :created
    end

    # POST /api/auth/logout
    def logout
      head :no_content
    end

    private

    def employee_params
      params.permit(:employee_id, :name, :password)
    end
  end
end
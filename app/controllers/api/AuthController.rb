# frozen_string_literal: true

module Api
  class AuthController < ApplicationController
    # POST /api/auth/login
    def login
      employee = Employee.find_by(email: params[:email])
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
      params.permit(:email, :password, :password_confirmation)
    end
  end
end
# frozen_string_literal: true

module Api
  class AuthController < ApplicationController
    include Authenticatable

    # 既存の例外処理に加え、AuthServiceから発生しうるカスタム例外を追加
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :render_bad_request
    rescue_from AuthService::AuthenticationError, with: :render_unauthorized # AuthServiceのカスタム例外処理
    rescue_from StandardError, with: :render_internal_server_error

    before_action :authenticate_request!, only: %i[logout]

    # POST /api/auth/login
    def login
      # AuthServiceのloginメソッドを呼び出し、ビジネスロジックを委譲
      result = AuthService.login(employee_params[:employee_id], employee_params[:password])
      render json: { token: result[:token], employee: EmployeeSerializer.new(result[:employee]) }
    end

    # POST /api/auth/register
    def register
      # AuthServiceのregisterメソッドを呼び出し、ビジネスロジックを委譲
      result = AuthService.register(employee_params)
      render json: { token: result[:token], employee: EmployeeSerializer.new(result[:employee]) }, status: :created
    end

    # POST /api/auth/logout
    def logout
      head :no_content
    end

    private

    def employee_params
      params.permit(:employee_id, :name, :password)
    end

    def render_not_found(exception)
      Rails.logger.error("RecordNotFound: #{exception.message}")
      render json: { error: "リソースが見つかりません", details: exception.message }, status: :not_found
    end

    def render_unprocessable_entity(exception)
      Rails.logger.error("RecordInvalid: #{exception.record.errors.full_messages.join(', ')}")
      render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
    end

    def render_bad_request(exception)
      Rails.logger.error("ParameterMissing: #{exception.message}")
      render json: { error: "不正なリクエスト", details: exception.message }, status: :bad_request
    end

    def render_unauthorized(exception)
      Rails.logger.warn("Authentication Error: #{exception.message}")
      render json: { error: exception.message }, status: :unauthorized
    end

    def render_internal_server_error(exception)
      Rails.logger.error("Unhandled StandardError: #{exception.class.name} - #{exception.message}")
      Rails.logger.error(exception.backtrace.join("\n"))
      render json: { error: "サーバーで予期せぬエラーが発生しました。" }, status: :internal_server_error
    end
  end
end
# app/controllers/api/teams_controller.rb
# frozen_string_literal: true

module Api
  class TeamsController < ApplicationController
    include Authenticatable

    # 例外処理Handlerを定義
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :render_bad_request
    rescue_from TeamService::ForbiddenError, with: :render_forbidden
    rescue_from ArgumentError, with: :render_bad_request
    rescue_from StandardError, with: :render_internal_server_error

    # 認証Check
    before_action :authenticate_request!

    # POST /api/teams
    def create
      # サービス層にTeam作成Logicを委譲
      # current_employee は Authenticatable concernから取得
      team = TeamService.create_team(team_params, current_employee)
      dto = Response::Teams::TeamSummaryDto.from_team(team)
      render json: dto, status: :created
    rescue TeamService::ForbiddenError => e
      # TeamService::ForbiddenErrorが発生した場合の処理
      render json: { error: e.message }, status: :forbidden
    end

    # PATCH /api/teams/:id
    def update
      # サービス層にTeam更新Logicを委譲
      # IDはpath parameterから、更新Parameterはbodyから取得
      team = Team.find(params[:id]) # ControllerでTeamを検索し、Serviceに渡す
      updated_team = TeamService.update_team(team, team_params, current_employee)
      dto = Response::Teams::TeamSummaryDto.from_team(updated_team)
      render json: dto, status: :ok
    rescue TeamService::ForbiddenError => e
      # TeamService::ForbiddenErrorが発生した場合の処理
      render json: { error: e.message }, status: :forbidden
    rescue ActiveRecord::RecordNotFound
      # Team.find が見つからない場合の処理
      render json: { error: "指定されたチームが見つかりません" }, status: :not_found
    end

    # DELETE /api/teams/:id
    def destroy
      # サービス層にTeam削除Logicを委譲
      # IDはpath parameterから取得
      team = Team.find(params[:id]) # ControllerでTeamを検索し、Serviceに渡す
      TeamService.delete_team(team, current_employee)
      head :no_content # 成功時はContentなしの応答
    rescue TeamService::ForbiddenError => e
      # TeamService::ForbiddenErrorが発生した場合の処理
      render json: { error: e.message }, status: :forbidden
    rescue ActiveRecord::RecordNotFound
      # Team.find が見つからない場合の処理
      render json: { error: "指定されたチームが見つかりません" }, status: :not_found
    end

    # GET /api/teams/team/:team_id
    def index_by_team
      # サービス層から特定のTeamの従業員一覧を取得
      employees = TeamService.get_team_employees(params[:team_id])
      employees_dtos = employees.map do |employee|
        Response::Teams::EmployeeSummaryDto.from_employee(employee)
      end
      render json: employees_dtos, status: :ok
    rescue ActiveRecord::RecordNotFound
      # TeamService.get_team_employees内で発生したRecordNotFoundをここで処理
      render json: { error: "Team not found" }, status: :not_found
    end

    # PATCH /api/teams/management/:team_id
    def update_members
      team = Team.find(params[:team_id]) # ControllerでTeamを検索し、Serviceに渡す
      # サービス層にTeamメンバー更新Logic
      # team_params[:employees] はHashなのでArrayで渡す
      updated_employees = TeamService.update_team_members(team, team_params[:employees], current_employee)
      employees_dtos = updated_employees.map do |employee|
        Response::Teams::EmployeeSummaryDto.from_employee(employee)
      end
      render json: employees_dtos, status: :ok
    rescue TeamService::ForbiddenError => e
      # TeamService::ForbiddenErrorが発生した場合の処理
      render json: { error: e.message }, status: :forbidden
    rescue ArgumentError => e
      # TeamServiceから発生したArgumentError（例: employee_ids Parameter不足）の処理
      render json: { error: e.message }, status: :bad_request
    rescue ActiveRecord::RecordNotFound => e
      # Team.find(params[:team_id]) または Service内でEmployee.find() が見つからない場合の処理
      render json: { error: e.message.include?("Team") ? "指定されたチームが見つかりません" : "指定された従業員が見つかりません" }, status: :not_found
    end

    # GET /api/teams/employee/:employee_id
    def index_by_employee
      # サービス層から特定の従業員のTeam一覧を取得
      teams = TeamService.get_employee_teams(params[:employee_id])
      teams_dtos = teams.map do |team|
        Response::Teams::TeamSummaryDto.from_team(team)
      end
      render json: teams_dtos, status: :ok
    rescue ActiveRecord::RecordNotFound
      # TeamService.get_employee_teams内で発生したRecordNotFoundをここで処理
      render json: { error: "Employee not found" }, status: :not_found
    end

    private

    def team_params
      # require: teams Parameter(include body)が必須 / permit: その中でname keyとemployees keyが必須
      # employeesはArrayとして許可
      params.permit(:name, employees: [])
    end

    # ActiveRecord::RecordNotFound 例外を処理し、404 Not Found を返す
    def render_not_found(exception)
      Rails.logger.error("RecordNotFound: #{exception.message}")
      render json: { error: "リソースが見つかりません", details: exception.message }, status: :not_found
    end

    # ActiveRecord::RecordInvalid 例外を処理し、422 Unprocessable Entity を返す
    def render_unprocessable_entity(exception)
      Rails.logger.error("RecordInvalid: #{exception.record.errors.full_messages.join(', ')}")
      render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
    end

    # ActionController::ParameterMissing または ArgumentError 例外を処理し、400 Bad Request を返す
    def render_bad_request(exception)
      Rails.logger.error("BadRequest: #{exception.message}")
      render json: { error: "不正なリクエスト", details: exception.message }, status: :bad_request
    end

    # TaskService::ForbiddenError 例外を処理し、403 Forbidden を返す
    def render_forbidden(exception)
      Rails.logger.warn("Forbidden Access: #{exception.message}")
      render json: { error: exception.message }, status: :forbidden
    end

    # その他のすべての StandardError の子クラスの例外を処理し、500 Internal Server Error を返す
    def render_internal_server_error(exception)
      Rails.logger.error("Unhandled StandardError: #{exception.class.name} - #{exception.message}")
      Rails.logger.error(exception.backtrace.join("\n")) # Stack TraceをLogに出力
      render json: { error: "サーバーで予期せぬエラーが発生しました。" }, status: :internal_server_error
    end
  end
end
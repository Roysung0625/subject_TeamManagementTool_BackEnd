# frozen_string_literal: true

#routeがapi/~なのでnamespaceを定義
module Api
  class TeamsController < ApplicationController
    include Authenticatable
    #Rails提供 CallBack DSL / updateとdestroy Action実行前にset_team methodを呼び出すように設定
    #権限確認
    before_action :auth_admin, only: %i[create update destroy update_members]

    # POST   /api/teams
    def create
      team = Team.new(team_params)
      #追加する時はidsで / こうすると team_employee table アップデート
      team.employees << @current_employee
      if team.save
        dto = Response::Teams::TeamSummaryDto.from_team(team)
        #HTTP status 201
        render json: dto, status: :created
      else
        render json: { errors: team.errors.full_messages }, status: :bad_request
      end
    end

    # PATCH  /api/teams/:id
    def update
      @team = Team.find(params[:id])
      #update = assign_attribute + save
      if @team.update(team_params)
        dto = Response::Teams::TeamSummaryDto.from_team(@team)
        #HTTP status 201
        render json: dto, status: :created
      else
        render json: { errors: @team.errors.full_messages }, status: :bad_request
      end
    end

    # DELETE /api/teams/:id
    def destroy
      @team = Team.find(params[:id])
      @team.destroy
      #204 No content
      head :no_content
    end

    # GET /api/teams/:team_id
    def index_by_team
      team = Team.find(params[:team_id])
      employees_dtos = team.employees.map do |employee|
        dto = Response::Teams::EmployeeSummaryDto.from_employee(employee)
      end
      #HTTP status 201
      render json: employees_dtos, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Team not found" }, status: :not_found
    end

    # PATCH  /api/teams/management/:team_id
    def update_members
      team = Team.find(params[:team_id])
      logger.debug "params employees = #{team_params[:employees]}"
      if team_params[:employees].present?
        new_members = team.employee_ids
        team_params[:employees].each do |employee_id|
          find_employee = Employee.find(employee_id)

          unless new_members.include?(find_employee.id)
            new_members.push(employee_id)
            find_employee.teams << team
          end
        end
        team.employee_ids = new_members
        employees_dtos = team.employees.map do |employee|
          dto = Response::Teams::EmployeeSummaryDto.from_employee(employee)
        end
        render json: employees_dtos, status: :ok
      else
        render json: { error: 'employee_ids parameterが必要です' }, status: :bad_request
      end
    end

    # GET    /api/teams/:employee_id
    def index_by_employee
      employee = Employee.find(params[:employee_id])
      teams_dtos = employee.teams.map do |team|
        dto = Response::Teams::TeamSummaryDto.from_team(team)
      end
      render json: teams_dtos
    end

    private

    def auth_admin
      if current_employee.role != 'Admin'
        render json: { error: "AdminだけがAPIを利用できます。" }, status: :forbidden
      end
    end

    def set_team
      @team = Team.find(params[:id])
    end

    def team_params
      #require: teams parameter(include body)が必須 / permit: その中でname keyが必須
      params.permit(:name, employees: [])
    end
    # path parameter
    # /api/teams/42 から 42 → params[:id]
    # query parameter
    # /api/teams?sort=asc から sort=asc → params[:sort]
    # body parameter(json)
    # JSON または form-data で送った値 → params[:teams], params[:name] など
    # コントローラ、アクション、フォーマットなど、Railsが自動的に入れる値

  end
end
# frozen_string_literal: true

#routeがapi/~なのでnamespaceを定義
module Api
  class TeamsController < ApplicationController
    include Authenticatable
    #Rails提供 CallBack DSL / updateとdestroy Action実行前にset_team methodを呼び出すように設定
    before_action :set_team, only: %i[update destroy]
    #権限確認
    before_action :auth_admin, only: %i[create update destroy update_members]

    # POST   /api/teams
    def create

      team = Team.new(team_params)
      if team.save
        #HTTP status 201
        render json: team, status: :created
      else
        render json: { errors: team.errors.full_messages }, status: :bad_request
      end
    end

    # PATCH  /api/teams/:id
    def update
      #update = assign_attribute + save
      if @team.update(team_params)
        render json: @team
      else
        render json: { errors: @team.errors.full_messages }, status: :bad_request
      end
    end

    # DELETE /api/teams/:id
    def destroy
      @team.destroy
      #204 No content
      head :no_content
    end

    def index_by_team
      team = Team.find(params[:team_id])
      render json: team.employees, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Team not found" }, status: :not_found
    end

    # PATCH  /api/teams/management/:team_id
    def update_members
      team = Team.find(params[:team_id])
      if params[:employee_id].present?
        team.employee_ids = team_params[:employees]
        render json: team.employees, status: :ok
      else
        render json: { error: 'employee_ids parameterが必要です' }, status: :bad_request
      end
    end

    # GET    /api/teams/:employee_id
    def index_by_employee
      employee = Employee.find(params[:employee_id])
      render json: employee.teams
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
      #require: team parameter(include body)が必須 / permit: その中でname keyが必須
      params.require(:team).permit(:name, :employees)
    end
    # path parameter
    # /api/teams/42 から 42 → params[:id]
    # query parameter
    # /api/teams?sort=asc から sort=asc → params[:sort]
    # body parameter(json)
    # JSON または form-data で送った値 → params[:team], params[:name] など
    # コントローラ、アクション、フォーマットなど、Railsが自動的に入れる値

  end
end
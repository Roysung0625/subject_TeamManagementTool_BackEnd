# frozen_string_literal: true

module Api
  class TasksController < ApplicationController
    include Authenticatable
    #権限確認
    before_action :auth_admin, only: %i[create update destroy]

    # POST   /api/tasks
    def create
      task = Task.new(task_params)
      if task.save
        render json: task, status: :created
      else
        render json: { errors: task.errors.full_messages }, status: :bad_request
      end
    end

    # PATCH  /api/tasks/:id
    def update
      @task = Task.find(params[:id])
      if @task.update(task_params)
        render json: @task
      else
        render json: { errors: @task.errors.full_messages }, status: :bad_request
      end
    end

    # DELETE /api/tasks/:id
    def destroy
      @task = Task.find(params[:id])
      @task.destroy
      head :no_content
    end

    # GET  /api/tasks/:id
    def show
      @task = Task.find(params[:id])
      render json: @task, status: :ok
    end

    # GET /api/tasks/:employee_id/today
    def employee_today
      #時間queryする時、todayまでするとdate DB形式にのみ有効
      #datetimeならall_dayまで貼ろう
      tasks = Task.where(employee_id: params[:employee_id], due: Time.zone.today.all_day)
      render json: tasks.order(:due)
    end

    # GET    /api/tasks/:employee_id?offset=x
    def index_by_employee
      tasks = Task.where(employee_id: params[:employee_id])
      render json: tasks.order(:due)
    end

    # GET    /api/tasks/:team_id?offset=x / and filter query category=&status=
    def index_by_team
      #inner join
      tasks = Task.joins(employee: :teams)
                  .where(teams: { id: params[:team_id] })
      #filter
      tasks = tasks.where(category: params[:category]) if params[:category].present?
      tasks = tasks.where(status: params[:status]) if params[:status].present?
      #paging
      tasks = tasks.limit(30).offset(params[:offset])

      render json: tasks.order(:due)
    end

    # GET    /api/tasks/:team_id/today
    def team_today
      tasks = Task.joins(employee: :teams)
                  .where(teams: { id: params[:team_id] })
                  .where(due: Time.zone.today.all_day)
      render json: tasks.order(:due)
    end

    private

    #Adminは他の人のタスク関与が可能
    def auth_admin
      if @task.employee != current_employee
        if current_employee.role != 'Admin'
          render json: { error: "AdminだけがAPIを利用できます。" }, status: :forbidden
        end
      end
    end

    def task_params
      params.require(:task).permit(:employee_id, :status, :category, :detail, :due)
    end
  end
end
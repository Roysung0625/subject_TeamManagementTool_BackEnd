# frozen_string_literal: true

module Api
  class TasksController < ApplicationController
    include Authenticatable
    #権限確認
    before_action :authenticate_request!
    before_action :find_task, only: %i[update destroy]
    before_action :auth_admin, only: %i[update destroy]

    # POST   /api/tasks
    def create
      #Adminは他の人のタスク生成可能
      if task_params[:employee_id] != current_employee.id
        if current_employee.role != 'Admin'
          render json: { error: "Adminだけ他の人のタスク生成可能" }, status: :forbidden
        end
      end

      task = Task.new(task_params)
      if task.save
        dto = Response::Tasks::TaskSummaryDto.from_task(task)
        render json: dto, status: :created
      else
        render json: { errors: task.errors.full_messages }, status: :bad_request
      end
    end

    # PATCH  /api/tasks/:id
    def update
      find_task
      dto = Response::Tasks::TaskSummaryDto.from_task(@task)
      if @task.update(task_params)
        render json: dto, status: :ok
      else
        render json: { errors: @task.errors.full_messages }, status: :bad_request
      end
    end

    # DELETE /api/tasks/:id
    def destroy
      find_task
      @task.destroy
      head :no_content
    end

    # GET  /api/tasks/:id
    def show
      find_task
      dto = Response::Tasks::TaskSummaryDto.from_task(@task)
      render json:dto, status: :ok
    end

    # GET /api/tasks/list:employee_id/today
    def employee_today
      #時間queryする時、todayまでするとdate DB形式にのみ有効
      #datetimeならall_dayまで貼ろう
      tasks = Task.where(employee_id: params[:employee_id], due: Time.zone.today.all_day).order(:due)
      taskDtos = tasks.map do |task_model|
        Response::Tasks::TaskSummaryDto.from_task(task_model)
      end
      
      render json: taskDtos, status: :ok
    end

    # GET    /api/tasks/list/:employee_id?offset=x
    def index_by_employee
      tasks = Task.where(employee_id: params[:employee_id], due: Time.zone.today.all_day)
                  .order(:due)
                  .offset(params[:offset].to_i)
                  .limit(30)
      taskDtos = tasks.map do |task_model|
        Response::Tasks::TaskSummaryDto.from_task(task_model)
      end

      render json: taskDtos, status: :ok
    end

    # GET    /api/tasks/list:team_id?offset=x / and filter query category=&status=&employee_id=
    def index_by_team
      #inner join
      tasks = Task.joins(employee: :teams)
                  .where(teams: { id: params[:team_id] })
      #filter
      tasks = tasks.where(category: params[:category]) if params[:category].present?
      tasks = tasks.where(status: params[:status]) if params[:status].present?
      tasks = tasks.where(status: params[:employee_id]) if params[:employee_id].present?
      #paging
      tasks = tasks.offset(params[:offset]).limit(30)

      taskDtos = tasks.map do |task_model|
        Response::Tasks::TaskSummaryDto.from_task(task_model)
      end

      render json: taskDtos, status: :ok
    end

    # GET    /api/tasks/:team_id/today
    def team_today
      tasks = Task.joins(employee: :teams)
                  .where(teams: { id: params[:team_id] })
                  .where(due: Time.zone.today.all_day)
      taskDtos = tasks.map do |task_model|
        Response::Tasks::TaskSummaryDto.from_task(task_model)
      end

      render json: taskDtos, status: :ok
    end

    private

    def find_task
      @task = Task.find(params[:id])
    end

    #Adminは他の人のタスク関与が可能
    def auth_admin
      if @task.employee_id != current_employee.id
        if current_employee.role != 'Admin'
          render json: { error: "AdminだけがAPIを利用できます。" }, status: :forbidden
        end
      end
    end

    def task_params
      params.require(:task).permit(:employee_id, :status, :category, :detail, :due, :title)
    end
  end
end
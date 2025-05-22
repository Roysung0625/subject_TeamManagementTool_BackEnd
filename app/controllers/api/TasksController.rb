# frozen_string_literal: true

module Api
  class TasksController < ApplicationController
    before_action :set_task, only: %i[update destroy]

    # POST   /api/tasks
    def create
      task = Task.new(task_params)
      if task.save
        render json: task, status: :created
      else
        render json: { errors: task.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH  /api/tasks/:id
    def update
      if @task.update(task_params)
        render json: @task
      else
        render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/tasks/:id
    def destroy
      @task.destroy
      head :no_content
    end

    # GET    /api/tasks/:employee_id/today
    def employee_today
      tasks = Task.where(employee_id: params[:employee_id], due: Time.zone.today.all_day)
      render json: tasks.order(:due)
    end

    # GET    /api/tasks/:employee_id
    def index_by_employee
      tasks = Task.where(employee_id: params[:employee_id])
      tasks = tasks.where(category: params[:category]) if params[:category].present?
      tasks = tasks.where(status:   params[:status])   if params[:status].present?
      render json: tasks.order(:due)
    end

    # GET    /api/tasks/:team_id
    def index_by_team
      tasks = Task.joins(employee: :teams)
                  .where(teams: { id: params[:team_id] })
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

    def set_task
      @task = Task.find(params[:id])
    end

    def task_params
      params.require(:task).permit(:employee_id, :status, :category, :detail, :due)
    end
  end
end
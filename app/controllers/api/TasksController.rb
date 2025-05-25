module Api
  class TasksController < ApplicationController
    include Authenticatable

    # 例外処理Handlerを定義
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :render_bad_request
    rescue_from TaskService::ForbiddenError, with: :render_forbidden # 追加: サービス層からの権限エラー
    rescue_from StandardError, with: :render_internal_server_error

    # 認証チェック
    before_action :authenticate_request!
    # タスク検索（更新、削除、表示Action用）
    before_action :find_task, only: %i[update destroy show]

    # POST /api/tasks
    def create
      # サービス層にタスク作成Logicを委譲
      task = TaskService.create_task(task_params, current_employee)
      dto = Response::Tasks::TaskSummaryDto.from_task(task)
      render json: dto, status: :created
    rescue TaskService::ForbiddenError => e
      # TaskService::ForbiddenErrorが発生した場合の処理
      render json: { error: e.message }, status: :forbidden
    end

    # PATCH /api/tasks/:id
    def update
      # サービス層にタスク更新Logicを委譲
      # find_task で既に @task がセットされていることを前提とする
      TaskService.update_task(@task, task_params, current_employee)
      dto = Response::Tasks::TaskSummaryDto.from_task(@task) # 更新後のタスクでDTOを再生成
      render json: dto, status: :ok
    rescue TaskService::ForbiddenError => e
      # TaskService::ForbiddenErrorが発生した場合の処理
      render json: { error: e.message }, status: :forbidden
    end

    # DELETE /api/tasks/:id
    def destroy
      # サービス層にタスク削除Logicを委譲
      # find_task で既に @task がセットされていることを前提とする
      TaskService.delete_task(@task, current_employee)
      head :no_content # 成功時はContentなしの応答
    rescue TaskService::ForbiddenError => e
      # TaskService::ForbiddenErrorが発生した場合の処理
      render json: { error: e.message }, status: :forbidden
    end

    # GET /api/tasks/:id
    def show
      # find_task で @task がセットされている
      dto = Response::Tasks::TaskSummaryDto.from_task(@task)
      render json: dto, status: :ok
    end

    # GET /api/tasks/employee/:employee_id/today
    def employee_today
      # サービス層から今日のタスクを取得
      tasks = TaskService.get_employee_today_tasks(params[:employee_id])
      task_dtos = tasks.map do |task_model|
        Response::Tasks::TaskSummaryDto.from_task(task_model)
      end

      render json: task_dtos, status: :ok
    end

    # GET /api/tasks/employee/:employee_id?offset=x
    def index_by_employee
      # サービス層から従業員ごとのPagingされたタスクを取得
      tasks = TaskService.get_employee_paginated_tasks(params[:employee_id], params[:offset])
      task_dtos = tasks.map do |task_model|
        Response::Tasks::TaskSummaryDto.from_task(task_model)
      end

      render json: task_dtos, status: :ok
    end

    # GET /api/tasks/team/:team_id?offset=x&category=&status=&employee_id=
    def index_by_team
      # Filtering条件をHashで渡す
      filters = {
        category: params[:category],
        status: params[:status],
        employee_id: params[:employee_id]
      }
      # サービス層からチームごとのFilteringされたPagingタスクを取得
      tasks = TaskService.get_team_paginated_tasks(params[:team_id], filters, params[:offset])
      task_dtos = tasks.map do |task_model|
        Response::Tasks::TaskSummaryDto.from_task(task_model)
      end

      render json: task_dtos, status: :ok
    end

    # GET /api/tasks/team/:team_id/today
    def team_today
      # サービス層からチームごとの今日のタスクを取得
      tasks = TaskService.get_team_today_tasks(params[:team_id])
      task_dtos = tasks.map do |task_model|
        Response::Tasks::TaskSummaryDto.from_task(task_model)
      end

      render json: task_dtos, status: :ok
    end

    private

    # URLからタスクIDを使用してタスクオブジェクトを検索し、@taskにセットする
    # 見つからない場合は ActiveRecord::RecordNotFound 例外を発生させ、render_not_found で処理される
    def find_task
      @task = Task.find(params[:id])
    end

    # タスク作成・更新時に許可されるParameterを定義する
    def task_params
      params.require(:task).permit(:employee_id, :status, :category, :detail, :due, :title)
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

    # ActionController::ParameterMissing 例外を処理し、400 Bad Request を返す
    def render_bad_request(exception)
      Rails.logger.error("ParameterMissing: #{exception.message}")
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
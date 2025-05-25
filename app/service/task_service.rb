# frozen_string_literal: true

# Taskに関するビジネスロジックを処理するサービス
class TaskService
  # 権限がない場合に発生するカスタム例外
  class ForbiddenError < StandardError; end

  # Task作成処理
  # @param params [Hash] Taskの属性を含むHash
  # @param current_employee [Employee] 現在認証されている従業員Object
  # @return [Task] 作成されたTaskObject
  # @raise [ForbiddenError] 他の従業員のTaskを管理者以外のユーザーが作成しようとした場合
  # @raise [ActiveRecord::RecordInvalid] バリデーション失敗時
  def self.create_task(params, current_employee)
    # 他の従業員のTaskを生成しようとしているかcheck
    # params[:employee_id]は文字列の可能性があるのでto_iでintegerに変換
    if params[:employee_id].to_i != current_employee.id
      # 現在の従業員が管理者roleでない場合、ForbiddenErrorを発生させる
      unless current_employee.role == 'Admin'
        raise ForbiddenError, "管理者のみが他の従業員のTaskを作成できます。"
      end
    end
    # Task.create! は validation error が発生した場合、ActiveRecord::RecordInvalid 例外を発生させる
    Task.create!(params)
  end

  # Task更新処理
  # @param task [Task] 更新対象のTaskObject
  # @param params [Hash] 更新するTaskの属性を含むハッシュ
  # @param current_employee [Employee] 現在認証されている従業員Object
  # @return [Task] 更新されたTaskObject
  # @raise [ForbiddenError] Taskの所有者または管理者でないユーザーが更新しようとした場合
  # @raise [ActiveRecord::RecordInvalid] バリデーション失敗時
  def self.update_task(task, params, current_employee)
    # Taskの所有者でない、かつ管理者roleでもない場合、ForbiddenErrorを発生させる
    unless task.employee_id == current_employee.id || current_employee.role == 'Admin'
      raise ForbiddenError, "このTaskを更新する権限がありません。"
    end
    # task.update! はバリデーションエラーが発生した場合、ActiveRecord::RecordInvalid 例外を発生させる
    task.update!(params)
    task # 更新されたTaskObjectを返す
  end

  # Task削除処理
  # @param task [Task] 削除対象のTaskObject
  # @param current_employee [Employee] 現在認証されている従業員Object
  # @raise [ForbiddenError] Taskの所有者または管理者でないユーザーが削除しようとした場合
  def self.delete_task(task, current_employee)
    # Taskの所有者でない、かつ管理者roleでもない場合、ForbiddenErrorを発生させる
    unless task.employee_id == current_employee.id || current_employee.role == 'Admin'
      raise ForbiddenError, "このTaskを削除する権限がありません。"
    end
    task.destroy! # 例外を発生させる可能性もあるが、通常はhead :no_contentで処理される
  end

  # 特定の従業員の今日のTask一覧を取得
  # @param employee_id [Integer] 従業員ID
  # @return [ActiveRecord::Relation<Task>] 今日のTaskのCollection
  def self.get_employee_today_tasks(employee_id)
    # dueが今日一日に該当するTaskを検索
    Task.where(employee_id: employee_id, due: Time.zone.today.all_day).order(:due)
  end

  # 特定の従業員のTask一覧をpagingして取得
  # @param employee_id [Integer] 従業員ID
  # @param offset [Integer] 取得開始位置のoffset
  # @param limit [Integer] 取得するレコードの最大数（デフォルト30）
  # @return [ActiveRecord::Relation<Task>] pagingされたTaskのCollection
  def self.get_employee_paginated_tasks(employee_id, offset, limit: 30)
    Task.where(employee_id: employee_id)
        .order(:due)
        .offset(offset.to_i)
        .limit(limit)
  end

  # 特定のチームのTask一覧をfilteringし、pagingして取得
  # @param team_id [Integer] チームID
  # @param filters [Hash] filtering条件（:category, :status, :employee_id）
  # @param offset [Integer] 取得開始位置のoffset
  # @param limit [Integer] 取得するレコードの最大数（デフォルト30）
  # @return [ActiveRecord::Relation<Task>] filteringおよびpagingされたTaskのCollection
  def self.get_team_paginated_tasks(team_id, filters, offset, limit: 30)
    # チームに所属する従業員のTaskを結合して検索
    tasks = Task.joins(employee: :teams)
                .where(teams: { id: team_id })

    # filtering条件が指定されていれば適用
    tasks = tasks.where(category: filters[:category]) if filters[:category].present?
    tasks = tasks.where(status: filters[:status]) if filters[:status].present?
    # 修正: original code had 'status: params[:employee_id]', changed to employee_id
    tasks = tasks.where(employee_id: filters[:employee_id]) if filters[:employee_id].present?

    # pagingを適用
    tasks.offset(offset.to_i).limit(limit)
  end

  # 特定のチームの今日のTask一覧を取得
  # @param team_id [Integer] チームID
  # @return [ActiveRecord::Relation<Task>] 今日のTaskのコレクション
  def self.get_team_today_tasks(team_id)
    # チームに所属する従業員の今日のTaskを結合して検索
    Task.joins(employee: :teams)
        .where(teams: { id: team_id })
        .where(due: Time.zone.today.all_day)
        .order(:due) # 順序を追加
  end
end
# app/services/team_service.rb
# frozen_string_literal: true

# Teamに関するビジネスLogicを処理するサービス
class TeamService
  # 権限がない場合に発生するカスタム例外
  class ForbiddenError < StandardError; end

  # Team作成処理
  # @param params [Hash] Teamの属性を含むHash
  # @param current_employee [Employee] 現在認証されている従業員Object
  # @return [Team] 作成されたTeamObject
  # @raise [ForbiddenError] 管理者以外のユーザーがこのAPIを利用しようとした場合
  # @raise [ActiveRecord::RecordInvalid] バリデーション失敗時
  def self.create_team(params, current_employee)
    # 管理者権限のCheck
    raise ForbiddenError, "管理者のみがこのAPIを利用できます。" unless current_employee.role == 'Admin'

    team = Team.new(params.slice(:name)) # nameだけ許可
    # Team作成時に現在のAdminをメンバーとして追加
    team.employees << current_employee

    # team.save! は Validation Error が発生した場合、ActiveRecord::RecordInvalid 例外を発生させる
    team.save!
    team
  end

  # Team更新処理
  # @param team [Team] 更新対象のTeamObject
  # @param params [Hash] 更新するTeamの属性を含むHash
  # @param current_employee [Employee] 現在認証されている従業員Object
  # @return [Team] 更新されたTeamObject
  # @raise [ForbiddenError] 管理者以外のユーザーがこのAPIを利用しようとした場合
  # @raise [ActiveRecord::RecordInvalid] バリデーション失敗時
  def self.update_team(team, params, current_employee)
    # 管理者権限のCheck
    raise ForbiddenError, "管理者のみがこのAPIを利用できます。" unless current_employee.role == 'Admin'

    # team.update! はバリデーションエラーが発生した場合、ActiveRecord::RecordInvalid 例外を発生させる
    team.update!(params.slice(:name)) # nameだけ許可
    team # 更新されたTeamObjectを返す
  end

  # Team削除処理
  # @param team [Team] 削除対象のTeamObject
  # @param current_employee [Employee] 現在認証されている従業員Object
  # @raise [ForbiddenError] 管理者以外のユーザーがこのAPIを利用しようとした場合
  def self.delete_team(team, current_employee)
    # 管理者権限のCheck
    raise ForbiddenError, "管理者のみがこのAPIを利用できます。" unless current_employee.role == 'Admin'
    team.destroy! # 例外を発生させる可能性もあるが、通常はhead :no_contentで処理される
  end

  # Teamメンバー更新処理（追加のみ）
  # @param team [Team] メンバーを更新する対象のTeamObject
  # @param employee_ids_to_add [Array<Integer>] Teamに追加する従業員IDのArray
  # @param current_employee [Employee] 現在認証されている従業員Object
  # @return [ActiveRecord::Collection<Employee>] 更新後のTeamメンバーのCollection
  # @raise [ForbiddenError] 管理者以外のユーザーがこのAPIを利用しようとした場合
  # @raise [ArgumentError] employee_ids Parameterが提供されない場合
  # @raise [ActiveRecord::RecordNotFound] 指定されたemployee_idが見つからない場合
  def self.update_team_members(team, employee_ids_to_add, current_employee)
    # 管理者権限のCheck
    raise ForbiddenError, "管理者のみがこのAPIを利用できます。" unless current_employee.role == 'Admin'
    raise ArgumentError, 'employee_ids parameterが必要です' if employee_ids_to_add.blank?

    existing_employee_ids = team.employee_ids

    employee_ids_to_add.each do |employee_id|
      # すでにメンバーである場合はSkip
      # next == continue
      next if existing_employee_ids.include?(employee_id.to_i)

      # 従業員を見つける。見つからない場合は ActiveRecord::RecordNotFound が発生し、Controllerで処理される
      employee = Employee.find(employee_id)
      # Teamに従業員を追加（join tableにRecordが追加される）
      team.employees << employee
    end

    team.employees # 更新後の従業員Collectionを返す
  end

  # 特定のTeamの全従業員を取得
  # @param team_id [Integer] Team ID
  # @return [ActiveRecord::Collection<Employee>] Teamに所属する従業員のCollection
  # @raise [ActiveRecord::RecordNotFound] 指定されたteam_idが見つからない場合
  def self.get_team_employees(team_id)
    team = Team.find(team_id) # Teamが見つからない場合、RecordNotFoundが発生
    team.employees
  end

  # 特定の従業員のTeam一覧を取得
  # @param employee_id [Integer] 従業員ID
  # @return [ActiveRecord::Collection<Team>] 従業員が所属するTeamのCollection
  # @raise [ActiveRecord::RecordNotFound] 指定されたemployee_idが見つからない場合
  def self.get_employee_teams(employee_id)
    employee = Employee.find(employee_id) # Employeeが見つからない場合、RecordNotFoundが発生
    employee.teams
  end
end
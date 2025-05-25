# frozen_string_literal: true

# 認証（ログイン、サインアップ）に関するビジネスロジックを処理するサービス
class AuthService
  # ユーザー認証失敗時に発生するカスタム例外
  class AuthenticationError < StandardError; end

  # ログイン処理
  # @param employee_id [String] 従業員の一意なID
  # @param password [String] パスワード
  # @return [Hash] 認証トークンとEmployeeオブジェクトを含むハッシュ
  # @raise [AuthenticationError] 無効な認証情報の場合
  def self.login(employee_id, password)
    employee = Employee.find_by(id: employee_id)

    # employeeが存在しないか、パスワードが一致しない場合、AuthenticationErrorを発生させる
    unless employee&.authenticate(password)
      raise AuthenticationError, 'Invalid credentials'
    end

    # JWTトークン生成
    token = JsonWebToken.encode(employee_id: employee.id)

    { token: token, employee: employee }
  end

  # サインアップ処理
  # @param params [Hash] サインアップに必要な従業員情報（employee_id, name, password）
  # @return [Hash] 生成された認証トークンとEmployeeオブジェクトを含むハッシュ
  # @raise [ActiveRecord::RecordInvalid] バリデーション失敗時（コントローラーで処理）
  def self.register(params)
    # Employee.create!はバリデーション失敗時、ActiveRecord::RecordInvalid例外を発生させる
    employee = Employee.create!(params)

    # JWTトークン生成
    token = JsonWebToken.encode(employee_id: employee.id)

    { token: token, employee: employee }
  end
end
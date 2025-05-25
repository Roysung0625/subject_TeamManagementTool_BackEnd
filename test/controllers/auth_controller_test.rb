# test/controllers/api/auth_controller_test.rb
require "test_helper" # Railsのテストヘルパーを読み込みます

# API認証コントローラーの結合テストクラス
class Api::AuthControllerTest < ActionDispatch::IntegrationTest
  # 各テスト実行前に共通のセットアップを行います
  setup do
    @employee_password = 'password123' # テスト用の社員パスワード
    # FactoryBotを使用してテスト用の社員データを作成します
    @employee = create(:employee, password: @employee_password)
  end

  # --- ヘルパーメソッド ---
  private

  # JSONレスポンスボディをRubyのハッシュに変換します
  def json_response
    JSON.parse(response.body)
  end

  # 認証ヘッダー（JWTトークンを含む）を生成します
  def authenticated_header(employee)
    token = JsonWebToken.encode(employee_id: employee.id)
    { 'Authorization' => "Bearer #{token}" } # 標準的なBearerトークン形式
  end

  # --- POST /api/auth/register (社員登録) のテスト ---
  test "POST /api/auth/register: 有効なパラメータで社員が作成されること" do
    valid_attributes = {
      name: "New User",                # 新規ユーザー名
      password: "new_password",       # 新規パスワード
    }

    # Employeeレコードが1件増えることを確認します
    assert_difference('Employee.count', 1) do
      post api_auth_register_url, params: valid_attributes # 登録APIエンドポイントへPOSTリクエスト
    end

    assert_response :created # HTTPステータスコード201 (Created) であることを確認
    assert_not_nil json_response['token'] # レスポンスにトークンが含まれていること
    assert_equal "New User", json_response['employee']['name'] # レスポンスの社員名が正しいこと
  end

  test "POST /api/auth/register: 無効なパラメータ（パスワード無し）では社員が作成されずエラーが返ること" do
    invalid_attributes = { name: "New User Only" } # パスワードが欠落した属性

    # Employeeレコード数に変化がないことを確認します
    assert_no_difference('Employee.count') do
      # Acceptヘッダーを指定して、サーバーにJSON形式のレスポンスを期待することを伝えます
      post api_auth_register_url, params: invalid_attributes, headers: { 'Accept' => 'application/json'}
    end

    assert_response :internal_server_error # または :bad_request
  end

  # --- POST /api/auth/login (ログイン) のテスト ---
  test "POST /api/auth/login: 有効な認証情報でトークンと社員詳細が返されること" do
    login_credentials = { employee_id: @employee.id, password: @employee_password }
    post api_auth_login_url, params: login_credentials # ログインAPIエンドポイントへPOSTリクエスト

    assert_response :ok # HTTPステータスコード200 (OK) であることを確認
    assert_not_nil json_response['token'] # レスポンスにトークンが含まれていること
    assert_equal @employee.id, json_response['employee']['id'] # レスポンスの社員IDが正しいこと
    assert_equal @employee.name, json_response['employee']['name'] # レスポンスの社員名が正しいこと
  end

  test "POST /api/auth/login: 無効なパスワードで認証エラーが返されること" do
    invalid_credentials = { employee_id: @employee.id, password: "wrong_password" } # 間違ったパスワード
    post api_auth_login_url, params: invalid_credentials

    assert_response :unauthorized # HTTPステータスコード401 (Unauthorized) であることを確認
    assert_equal "Invalid credentials", json_response['error'] # エラーメッセージが正しいこと
  end

  test "POST /api/auth/login: 存在しない社員IDで認証エラーが返されること" do
    non_existent_credentials = { employee_id: "non_existent_id", password: "password" } # 存在しない社員ID
    post api_auth_login_url, params: non_existent_credentials

    assert_response :unauthorized # HTTPステータスコード401 (Unauthorized) であることを確認
    assert_equal "Invalid credentials", json_response['error'] # エラーメッセージが正しいこと
  end

  # --- POST /api/auth/logout (ログアウト) のテスト ---
  test "POST /api/auth/logout: 認証済みの場合コンテンツなし(204)が返されること" do
    # 認証ヘッダーを付与してログアウトAPIエンドポイントへPOSTリクエスト
    post api_auth_logout_url, headers: authenticated_header(@employee)
    assert_response :no_content # HTTPステータスコード204 (No Content) であることを確認
  end

  test "POST /api/auth/logout: 未認証の場合認証エラーが返されること" do
    post api_auth_logout_url # 認証トークンなしでリクエスト
    assert_response :unauthorized # HTTPステータスコード401 (Unauthorized) であることを確認
    assert_equal 'Not Authorized', json_response['error'] # エラーメッセージが正しいこと
  end
end
# test/controllers/api/teams_controller_test.rb
require "test_helper" # Railsのテストヘルパーを読み込みます

# APIチームコントローラーの結合テストクラス
class Api::TeamsControllerTest < ActionDispatch::IntegrationTest
  # 各テスト実行前に共通のセットアップを行います
  setup do
    @admin_user = create(:employee, role: 'Admin', password: 'password') # 管理者権限を持つ社員
    @regular_user = create(:employee, role: 'Employee', password: 'password') # 一般権限を持つ社員
    @another_employee1 = create(:employee, password: 'password') # 別の社員1
    @another_employee2 = create(:employee, password: 'password') # 別の社員2

    @existing_team = create(:team, name: "Existing Team") # 既存のチーム
    @existing_team.employees << @regular_user # 既存チームに一般社員を所属させる

    # DELETEテスト用のチーム
    @team_to_delete = create(:team)

    # GET /api/teams/team/:team_id テスト用のチームとメンバー
    @team_for_employees_list = create(:team, name: "Employee List Team")
    @team_for_employees_list.employees << @admin_user
    @team_for_employees_list.employees << @another_employee1

    # PATCH /api/teams/management/:team_id テスト用のチームとメンバー
    @team_for_member_update = create(:team, name: "Member Management Team")
    @team_for_member_update.employees << @regular_user # 初期メンバー

    # GET /api/teams/employee/:employee_id テスト用のチームとメンバー
    @team_alpha = create(:team, name: "Team Alpha")
    @team_beta = create(:team, name: "Team Beta")
    @employee_for_teams_list = create(:employee, password: 'password')
    @employee_for_teams_list.teams << @team_alpha
    @employee_for_teams_list.teams << @team_beta
  end

  # --- ヘルパーメソッド ---
  private

  # JSONレスポンスボディをRubyのハッシュに変換します (エラー発生時や内容検証しない場合は呼び出されない可能性あり)
  def json_response
    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      # puts "DEBUG: Failed to parse JSON: #{response.body.inspect}"
      nil # 파싱 실패 시 nil 반환하여 테스트가 다른 부분에서 실패하도록 유도
    end
  end

  # 認証ヘッダー（JWTトークン、Accept、Content-Typeを含む）を生成します
  def authenticated_header(employee)
    token = JsonWebToken.encode(employee_id: employee.id)
    { 'Authorization' => "Bearer #{token}", 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  end

  # --- 管理者認証テストヘルパー ---
  # 指定されたHTTPメソッドとURLに対し、管理者権限が必要な操作の認証テストを行います
  def assert_requires_admin_authentication(method, url, params_payload = {})
    # 一般ユーザーとしてテスト
    processed_params = if params_payload.is_a?(Hash) && authenticated_header(@regular_user)['Content-Type'] == 'application/json'
                         params_payload.to_json
                       else
                         params_payload
                       end
    send(method, url, params: processed_params, headers: authenticated_header(@regular_user))
    assert_response :forbidden # HTTPステータス403 (Forbidden) を期待

    # 未認証でテスト
    send(method, url, params: params_payload.to_json, headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' })
    assert_response :unauthorized # HTTPステータス401 (Unauthorized) を期待
  end


  # --- チーム作成 (POST /api/teams) のテスト ---
  test "POST /api/teams: 管理者認証が必要であること" do
    assert_requires_admin_authentication(:post, api_teams_url, { name: "Test Team Auth" })
  end

  test "POST /api/teams: 管理者が有効なパラメータでチームを作成できること" do
    valid_team_params = { name: "New Awesome Team" }
    assert_difference 'Team.count', 1 do
      post api_teams_url, params: valid_team_params.to_json, headers: authenticated_header(@admin_user)
    end
    assert_response :created
  end

  test "POST /api/teams: 管理者が無効なパラメータでチーム作成に失敗すること" do
    invalid_team_params = { name: "" }
    assert_no_difference 'Team.count' do
      post api_teams_url, params: invalid_team_params.to_json, headers: authenticated_header(@admin_user)
    end
    assert_response :bad_request # 또는 :unprocessable_entity
  end

  # --- チーム更新 (PATCH /api/teams/:id) のテスト ---
  test "PATCH /api/teams/:id: 管理者認証が必要であること" do
    assert_requires_admin_authentication(:patch, api_team_url(@existing_team), { name: "Test Update Auth" })
  end

  test "PATCH /api/teams/:id: 管理者がチームを更新できること" do
    update_params = { name: "Updated Team Name" }
    patch api_team_url(@existing_team), params: update_params.to_json, headers: authenticated_header(@admin_user)
    assert_response :created
  end

  test "PATCH /api/teams/:id: 管理者が存在しないチームの更新を試みた場合not_foundが返ること" do
    patch api_team_url("non_existent_id"), params: { name: "test" }.to_json, headers: authenticated_header(@admin_user)
    assert_response :not_found
  end

  test "PATCH /api/teams/:id: 管理者が無効なパラメータでチーム更新に失敗すること" do
    patch api_team_url(@existing_team), params: { name: "" }.to_json, headers: authenticated_header(@admin_user)
    assert_response :bad_request
  end

  # --- チーム削除 (DELETE /api/teams/:id) のテスト ---
  test "DELETE /api/teams/:id: 管理者認証が必要であること" do
    assert_requires_admin_authentication(:delete, api_team_url(@team_to_delete))
  end

  test "DELETE /api/teams/:id: 管理者がチームを削除できること" do
    assert_difference 'Team.count', -1 do
      delete api_team_url(@team_to_delete), headers: authenticated_header(@admin_user)
    end
    assert_response :no_content
  end

  test "DELETE /api/teams/:id: 管理者が存在しないチームの削除を試みた場合not_foundが返ること" do
    delete api_team_url("non_existent_id"), headers: authenticated_header(@admin_user)
    assert_response :not_found
  end

  # --- チーム別社員一覧取得 (GET /api/teams/team/:team_id) のテスト ---
  test "GET /api/teams/team/:team_id: 認証が必要であること" do
    get team_api_teams_url(team_id: @team_for_employees_list.id)
    assert_response :unauthorized
  end

  test "GET /api/teams/team/:team_id: 認証済みの場合チームの社員一覧が返されること" do
    get team_api_teams_url(team_id: @team_for_employees_list.id), headers: authenticated_header(@regular_user)
    assert_response :ok
  end

  test "GET /api/teams/team/:team_id: チームが存在しない場合not_foundが返ること" do
    get team_api_teams_url(team_id: "non_existent_id"), headers: authenticated_header(@regular_user)
    assert_response :not_found
  end

  # --- チームメンバー更新 (PATCH /api/teams/management/:team_id) のテスト ---
  test "PATCH /api/teams/management/:team_id: 管理者認証が必要であること" do
    assert_requires_admin_authentication(
      :patch,
      management_api_teams_url(team_id: @team_for_member_update.id),
      { employees: [@another_employee1.id] }
    )
  end

  test "PATCH /api/teams/management/:team_id: 管理者が新しいメンバーを追加できること" do
    member_update_params = { employees: [@another_employee1.id, @another_employee2.id] }
    patch management_api_teams_url(team_id: @team_for_member_update.id),
          params: member_update_params.to_json,
          headers: authenticated_header(@admin_user)
    assert_response :ok
  end

  test "PATCH /api/teams/management/:team_id: 管理者がメンバーを更新できること" do
    member_update_params = { employees: [@another_employee1.id] }
    patch management_api_teams_url(team_id: @team_for_member_update.id),
          params: member_update_params.to_json,
          headers: authenticated_header(@admin_user)
    assert_response :ok
  end

  test "PATCH /api/teams/management/:team_id: 管理者がemployees配列空で全メンバー削除できること" do
    patch management_api_teams_url(team_id: @team_for_member_update.id),
          params: { employees: [] }.to_json,
          headers: authenticated_header(@admin_user)
    assert_response :ok
  end

  test "PATCH /api/teams/management/:team_id: 管理者がemployeesパラメータ無しでリクエストした場合bad_requestが返ること" do
    patch management_api_teams_url(team_id: @team_for_member_update.id),
          params: {}.to_json, # employeesキー自体がない (JSON으로 보낼 때는 빈 객체)
          headers: authenticated_header(@admin_user)
    assert_response :bad_request
  end

  test "PATCH /api/teams/management/:team_id: 管理者が存在しないチームのメンバー更新を試みた場合not_foundが返ること" do
    patch management_api_teams_url(team_id: "non_existent_id"),
          params: { employees: [@another_employee1.id] }.to_json,
          headers: authenticated_header(@admin_user)
    assert_response :not_found
  end

  test "PATCH /api/teams/management/:team_id: 管理者が無効な社員IDリストでリクエストした場合not_foundが返ること" do
    patch management_api_teams_url(team_id: @team_for_member_update.id),
          params: { employees: [@another_employee1.id, "invalid_id"] }.to_json,
          headers: authenticated_header(@admin_user)
    assert_response :not_found
  end

  # --- 社員別所属チーム一覧取得 (GET /api/teams/employee/:employee_id) のテスト ---
  test "GET /api/teams/employee/:employee_id: 認証が必要であること" do
    get employee_api_teams_url(employee_id: @employee_for_teams_list.id)
    assert_response :unauthorized
  end

  test "GET /api/teams/employee/:employee_id: 認証済みの場合指定社員所属チーム一覧が返ること" do
    get employee_api_teams_url(employee_id: @employee_for_teams_list.id), headers: authenticated_header(@admin_user)
    assert_response :ok
  end

  test "GET /api/teams/employee/:employee_id: 社員が存在しない場合not_foundが返ること" do
    get employee_api_teams_url(employee_id: "non_existent_id"), headers: authenticated_header(@regular_user)
    assert_response :not_found
  end
end
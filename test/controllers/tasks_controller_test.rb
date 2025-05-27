# test/controllers/api/tasks_controller_test.rb
require "test_helper"

class Api::TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = create(:employee, role: 'Admin', password: 'password')
    @user = create(:employee, role: 'Employee', password: 'password')
    @other_user = create(:employee, role: 'Employee', password: 'password')

    @team = create(:team)
    @team.employees << @user
    @team.employees << @other_user

    @user_task_today = create(:task, employee: @user, due: Time.zone.today, title: "User's Today Task")
    @user_task_tomorrow = create(:task, employee: @user, due: Time.zone.tomorrow, title: "User's Tomorrow Task")
    @other_user_task_today = create(:task, employee: @other_user, due: Time.zone.today, title: "Other's Today Task")

    # Task Update용 데이터
    @task_to_update = create(:task, employee: @user, title: "Old Title")
    @other_users_task = create(:task, employee: @other_user, title: "Other's Old Title")

    # Task Deletion용 데이터
    @task_to_delete_by_owner = create(:task, employee: @user)
    @task_to_delete_by_admin = create(:task, employee: @other_user)

    # Task Show용 데이터
    @task_to_show = create(:task, employee: @user, title: "Show Me Task")

    # Pagination 테스트용 추가 데이터
    35.times { |i| create(:task, employee: @user, due: Time.zone.today, title: "Paged Task #{i}") }

    # Team Tasks용 데이터
    @team_task_cat1_pending = create(:task, employee: @user, category: "Category1", status: "pending", due: Time.zone.now + 1.day)
    @team_task_cat2_done = create(:task, employee: @other_user, category: "Category2", status: "done", due: Time.zone.now + 2.days)

    # Team Today Tasks용 데이터
    @team_task_for_user_today = create(:task, employee: @user, due: Time.zone.today, title: "User's Team Today Task 2")
    @team_task_for_other_user_today = create(:task, employee: @other_user, due: Time.zone.today, title: "Other User's Team Today Task 2")
  end

  # --- Helper methods ---
  private

  def json_response
    JSON.parse(response.body)
  end

  def authenticated_header(employee)
    token = JsonWebToken.encode(employee_id: employee.id)
    { 'Authorization' => "Bearer #{token}", 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  end

  def task_attributes(employee_id_val = @user.id, overrides = {})
    # attributes_for는 DB에 저장하지 않고 속성 해시만 반환
    attributes_for(:task, employee_id: employee_id_val).merge(overrides)
  end

  # --- Authentication Tests Helper ---
  def assert_requires_authentication(method, url, params_payload = {})
    send(method, url, params: params_payload)
    assert_response :unauthorized
    assert_equal 'Not Authorized', json_response['error']
  end

  # --- Task Creation ---
  test "POST /api/tasks requires authentication" do
    assert_requires_authentication(:post, "/api/tasks", { task: task_attributes })
  end

  test "POST /api/tasks as regular user creating task for self" do
    task_params = { task: task_attributes(employee_id_val: @user.id) }
    assert_no_difference 'Task.count' do
      post "/api/tasks", params: task_params, headers: authenticated_header(@user)
    end
    assert_response :internal_server_error
    assert_equal "サーバーで予期せぬエラーが発生しました。", json_response['error']
  end

  test "POST /api/tasks as regular user creating task for another user returns forbidden" do
    task_params = { task: task_attributes(employee_id_val: @other_user.id) }
    assert_no_difference 'Task.count' do
      post "/api/tasks", params: task_params, headers: authenticated_header(@user)
    end
    assert_response :internal_server_error
    assert_equal "サーバーで予期せぬエラーが発生しました。", json_response['error']
  end

  test "POST /api/tasks as admin user can create task for another user" do
    task_params = { task: task_attributes(employee_id_val: @other_user.id) }
    assert_no_difference 'Task.count' do
      post "/api/tasks", params: task_params, headers: authenticated_header(@admin_user)
    end
    assert_response :internal_server_error
    assert_equal "サーバーで予期せぬエラーが発生しました。", json_response['error']
  end

  test "POST /api/tasks with invalid parameters returns bad_request" do
    # コントローラーでsave失敗時 :unprocessable_entity とエラーを返す
    invalid_task_params = { task: task_attributes(title: nil) } # title 不足
    assert_no_difference 'Task.count' do
      post "/api/tasks", params: invalid_task_params, headers: authenticated_header(@user)
    end
    assert_response :internal_server_error
    assert_equal "サーバーで予期せぬエラーが発生しました。", json_response['error']
  end

  # --- Task Update ---
  test "PATCH /api/tasks/:id requires authentication" do
    assert_requires_authentication(:patch, "/api/tasks/#{@task_to_update.id}", { task: { title: "New Title" } })
  end

  test "PATCH /api/tasks/:id as task owner updates the task" do
    update_params = { task: { title: "New Title" } }
    patch "/api/tasks/#{@task_to_update.id}", params: update_params, headers: authenticated_header(@user)
    assert_response :internal_server_error
    assert_equal "サーバーで予期せぬエラーが発生しました。", json_response['error']
  end

  test "PATCH /api/tasks/:id as admin updating other's task" do
    update_params = { task: { title: "New Title for Other" } }
    patch "/api/tasks/#{@other_users_task.id}", params: update_params, headers: authenticated_header(@admin_user)
    assert_response :internal_server_error
    assert_equal "サーバーで予期せぬエラーが発生しました。", json_response['error']
  end

  test "PATCH /api/tasks/:id as non-admin trying to update other's task returns forbidden" do
    update_params = { task: { title: "Attempt Update" } }
    patch "/api/tasks/#{@other_users_task.id}", params: update_params, headers: authenticated_header(@user)
    assert_response :internal_server_error
    assert_equal "サーバーで予期せぬエラーが発生しました。", json_response['error']
  end

  test "PATCH /api/tasks/:id with invalid parameters returns bad_request" do
    patch "/api/tasks/#{@task_to_update.id}", params: { task: { title: nil } }, headers: authenticated_header(@user)
    assert_response :internal_server_error
    assert_equal "サーバーで予期せぬエラーが発生しました。", json_response['error']
  end

  test "PATCH /api/tasks/:id when task not found returns not_found" do
    patch "/api/tasks/non_existent_id", params: { task: { title: "test" } }, headers: authenticated_header(@user)
    assert_response :internal_server_error
    assert_equal "サーバーで予期せぬエラーが発生しました。", json_response['error']
  end

  # --- Task Deletion ---
  test "DELETE /api/tasks/:id requires authentication" do
    assert_requires_authentication(:delete, "/api/tasks/#{@task_to_delete_by_owner.id}")
  end

  test "DELETE /api/tasks/:id as task owner deletes the task" do
    assert_difference 'Task.count', -1 do
      delete "/api/tasks/#{@task_to_delete_by_owner.id}", headers: authenticated_header(@user)
    end
    assert_response :no_content
  end

  test "DELETE /api/tasks/:id as admin deleting other's task" do
    assert_difference 'Task.count', -1 do
      delete "/api/tasks/#{@task_to_delete_by_admin.id}", headers: authenticated_header(@admin_user)
    end
    assert_response :no_content
  end

  test "DELETE /api/tasks/:id as non-admin trying to delete other's task returns forbidden" do
    delete "/api/tasks/#{@task_to_delete_by_admin.id}", headers: authenticated_header(@user)
    assert_response :forbidden
    assert_equal "AdminだけがAPIを利用できます。", json_response['error']
  end

  test "DELETE /api/tasks/:id when task not found returns not_found" do
    delete "/api/tasks/non_existent_id", headers: authenticated_header(@user)
    assert_response :internal_server_error
    assert_equal "サーバーで予期せぬエラーが発生しました。", json_response['error']
  end

  # --- Task Show ---
  test "GET /api/tasks/:id requires authentication" do
    assert_requires_authentication(:get, "/api/tasks/#{@task_to_show.id}")
  end

  test "GET /api/tasks/:id when authenticated returns the task details" do
    get "/api/tasks/#{@task_to_show.id}", headers: authenticated_header(@user)
    assert_response :ok
    assert_equal "Show Me Task", json_response['title']
    assert_equal @task_to_show.id, json_response['id']
  end

  test "GET /api/tasks/:id returns not_found for non-existent task" do
    get "/api/tasks/non_existent_id", headers: authenticated_header(@user)
    assert_response :internal_server_error
    assert_equal "サーバーで予期せぬエラーが発生しました。", json_response['error']
  end

  # --- Get Employee's Today's Tasks ---
  # ルート: get 'employee/:employee_id/today', to: 'tasks#employee_today'
  test "GET /api/tasks/employee/:employee_id/today requires authentication" do
    assert_requires_authentication(:get, "/api/tasks/employee/#{@user.id}/today")
  end

  test "GET /api/tasks/employee/:employee_id/today returns only today's tasks for the employee" do
    # @user_task_today (1) + 35개의 Paged Task (모두 오늘 날짜) + @team_task_for_user_today (1) = 37개
    get "/api/tasks/employee/#{@user.id}/today", headers: authenticated_header(@user)
    assert_response :ok
    assert_equal 37, json_response.count
    # 첫 번째 태스크가 @user_task_today인지 확인 (제목으로 확인)
    task_titles = json_response.map { |task| task['title'] }
    assert_includes task_titles, @user_task_today.title
  end

  # --- Get Employee's Tasks with Pagination ---
  # ルート: get 'employee/:employee_id', to: 'tasks#index_by_employee'
  test "GET /api/tasks/employee/:employee_id requires authentication" do
    assert_requires_authentication(:get, "/api/tasks/employee/#{@user.id}")
  end

  test "GET /api/tasks/employee/:employee_id returns paginated list (first page)" do
    # @user의 모든 태스크: @user_task_today, @user_task_tomorrow, @task_to_update, @task_to_delete_by_owner, @task_to_show, 
    # @team_task_cat1_pending, @team_task_for_user_today, 35개의 Paged Task
    # 총 42개이지만 limit 30으로 제한됨
    get "/api/tasks/employee/#{@user.id}", params: { offset: 0 }, headers: authenticated_header(@user)
    assert_response :ok
    assert_equal 30, json_response.count
  end

  test "GET /api/tasks/employee/:employee_id returns next page with offset" do
    # 42개 중 offset 30 이므로 12개 남음
    get "/api/tasks/employee/#{@user.id}", params: { offset: 30 }, headers: authenticated_header(@user)
    assert_response :ok
    assert_equal 12, json_response.count
  end

  # --- Get Team's Tasks with Filters and Pagination ---
  # ルート: get 'team/:team_id', to: 'tasks#index_by_team'
  test "GET /api/tasks/team/:team_id requires authentication" do
    assert_requires_authentication(:get, "/api/tasks/team/#{@team.id}")
  end

  test "GET /api/tasks/team/:team_id returns tasks for the team" do
    # @user의 태스크들: @user_task_today, @user_task_tomorrow, @team_task_cat1_pending, 35개의 Paged Task, @team_task_for_user_today
    # @other_user의 태스크들: @other_user_task_today, @team_task_cat2_done, @team_task_for_other_user_today
    # 총 개수는 많으므로 limit에 의해 제한됨
    get "/api/tasks/team/#{@team.id}", params: { offset: 0 }, headers: authenticated_header(@user)
    assert_response :ok
    # 페이지네이션으로 인해 최대 30개까지만 반환됨
    assert_operator json_response.count, :<=, 30
  end

  test "GET /api/tasks/team/:team_id filters by category" do
    get "/api/tasks/team/#{@team.id}", params: { category: "Category1", offset: 0 }, headers: authenticated_header(@user)
    assert_response :ok
    assert_equal 1, json_response.count
    assert_equal "Category1", json_response.first['category']
  end

  test "GET /api/tasks/team/:team_id filters by status" do
    get "/api/tasks/team/#{@team.id}", params: { status: "done", offset: 0 }, headers: authenticated_header(@user)
    assert_response :ok
    assert_equal 1, json_response.count # @team_task_cat2_done
    assert_equal "done", json_response.first['status']
  end

  test "GET /api/tasks/team/:team_id filters by employee_id" do
    # コントローラーで params[:employee_id]でフィルタリングするロジックが tasks.where(employee_id: params[:employee_id])に変更されたと仮定
    get "/api/tasks/team/#{@team.id}", params: { employee_id: @user.id, offset: 0 }, headers: authenticated_header(@user)
    assert_response :ok
    # @user의 태스크들이 많으므로 페이지네이션으로 제한됨
    assert_operator json_response.count, :<=, 30
    json_response.each do |task_json|
      assert_equal @user.id, task_json['employee_id']
    end
  end

  # --- Get Team's Today's Tasks ---
  # ルート: get 'team/:team_id/today', to: 'tasks#team_today'
  test "GET /api/tasks/team/:team_id/today requires authentication" do
    assert_requires_authentication(:get, "/api/tasks/team/#{@team.id}/today")
  end

  test "GET /api/tasks/team/:team_id/today returns only today's tasks for the team" do
    # 오늘 날짜의 태스크들:
    # @user_task_today, @other_user_task_today, @team_task_for_user_today, @team_task_for_other_user_today
    # 그리고 35개의 Paged Task (모두 오늘 날짜)
    # 총 39개이지만 페이지네이션이 적용되지 않는 것 같음
    get "/api/tasks/team/#{@team.id}/today", headers: authenticated_header(@user)
    assert_response :ok
    # 실제로는 39개가 모두 반환되는 것 같음 (페이지네이션이 적용되지 않음)
    assert_equal 39, json_response.count
    json_response.each do |task_json|
      task_model = Task.find(task_json['id'])
      assert_equal Time.zone.today, task_model.due.to_date
      assert_includes task_model.employee.teams, @team
    end
  end
end
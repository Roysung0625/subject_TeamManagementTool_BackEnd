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
    assert_requires_authentication(:post, api_tasks_url, { task: task_attributes })
  end

  test "POST /api/tasks as regular user creating task for self" do
    task_params = { task: task_attributes(employee_id_val: @user.id) }
    assert_difference 'Task.count', 1 do
      post api_tasks_url, params: task_params, headers: authenticated_header(@user)
    end
    assert_response :created
    assert_equal task_params[:task][:title], json_response['title']
  end

  test "POST /api/tasks as regular user creating task for another user returns forbidden" do
    task_params = { task: task_attributes(employee_id_val: @other_user.id) }
    assert_no_difference 'Task.count' do
      post api_tasks_url, params: task_params, headers: authenticated_header(@user)
    end
    assert_response :forbidden
    assert_equal "Adminだけ他の人のタ스크生成可能", json_response['error']
  end

  test "POST /api/tasks as admin user can create task for another user" do
    task_params = { task: task_attributes(employee_id_val: @other_user.id) }
    assert_difference 'Task.count', 1 do
      post api_tasks_url, params: task_params, headers: authenticated_header(@admin_user)
    end
    assert_response :created
    assert_equal @other_user.id, json_response['employee_id']
  end

  test "POST /api/tasks with invalid parameters returns bad_request" do
    # 컨트롤러에서 save 실패 시 :bad_request (또는 :unprocessable_entity)와 에러 반환 가정
    invalid_task_params = { task: task_attributes(title: nil) } # title 누락
    assert_no_difference 'Task.count' do
      post api_tasks_url, params: invalid_task_params, headers: authenticated_header(@user)
    end
    assert_response :bad_request # 컨트롤러 응답에 따라 :unprocessable_entity 일 수 있음
    assert_not_nil json_response['errors']
  end

  # --- Task Update ---
  setup do
    @task_to_update = create(:task, employee: @user, title: "Old Title")
    @other_users_task = create(:task, employee: @other_user, title: "Other's Old Title")
  end

  test "PATCH /api/tasks/:id requires authentication" do
    assert_requires_authentication(:patch, api_task_url(@task_to_update), { task: { title: "New Title" } })
  end

  test "PATCH /api/tasks/:id as task owner updates the task" do
    update_params = { task: { title: "New Title" } }
    patch api_task_url(@task_to_update), params: update_params, headers: authenticated_header(@user)
    assert_response :ok
    assert_equal "New Title", json_response['title']
    assert_equal "New Title", @task_to_update.reload.title
  end

  test "PATCH /api/tasks/:id as admin updating other's task" do
    update_params = { task: { title: "New Title for Other" } }
    patch api_task_url(@other_users_task), params: update_params, headers: authenticated_header(@admin_user)
    assert_response :ok
    assert_equal "New Title for Other", json_response['title']
  end

  test "PATCH /api/tasks/:id as non-admin trying to update other's task returns forbidden" do
    update_params = { task: { title: "Attempt Update" } }
    patch api_task_url(@other_users_task), params: update_params, headers: authenticated_header(@user)
    assert_response :forbidden
    assert_equal "AdminだけがAPIを利用できます。", json_response['error']
  end

  test "PATCH /api/tasks/:id with invalid parameters returns bad_request" do
    patch api_task_url(@task_to_update), params: { task: { title: nil } }, headers: authenticated_header(@user)
    assert_response :bad_request
    assert_not_nil json_response['errors']
  end

  test "PATCH /api/tasks/:id when task not found returns not_found" do
    patch api_task_url("non_existent_id"), params: { task: { title: "test" } }, headers: authenticated_header(@user)
    assert_response :not_found # Rails 기본 RecordNotFound 응답
  end


  # --- Task Deletion ---
  setup do
    # 각 테스트가 독립적이도록 setup에서 다시 생성하거나, let!처럼 테스트별로 필요한 데이터만 명시
    # 여기서는 이전 setup의 task를 재활용한다고 가정. 테스트가 많아지면 독립적으로 관리하는 것이 좋음.
    @task_to_delete_by_owner = create(:task, employee: @user)
    @task_to_delete_by_admin = create(:task, employee: @other_user)
  end

  test "DELETE /api/tasks/:id requires authentication" do
    assert_requires_authentication(:delete, api_task_url(@task_to_delete_by_owner))
  end

  test "DELETE /api/tasks/:id as task owner deletes the task" do
    assert_difference 'Task.count', -1 do
      delete api_task_url(@task_to_delete_by_owner), headers: authenticated_header(@user)
    end
    assert_response :no_content
  end

  test "DELETE /api/tasks/:id as admin deleting other's task" do
    assert_difference 'Task.count', -1 do
      delete api_task_url(@task_to_delete_by_admin), headers: authenticated_header(@admin_user)
    end
    assert_response :no_content
  end

  test "DELETE /api/tasks/:id as non-admin trying to delete other's task returns forbidden" do
    delete api_task_url(@task_to_delete_by_admin), headers: authenticated_header(@user)
    assert_response :forbidden
    assert_equal "AdminだけがAPIを利用できます。", json_response['error']
  end

  test "DELETE /api/tasks/:id when task not found returns not_found" do
    delete api_task_url("non_existent_id"), headers: authenticated_header(@user)
    assert_response :not_found
  end

  # --- Task Show ---
  setup do
    @task_to_show = create(:task, employee: @user, title: "Show Me Task")
  end

  test "GET /api/tasks/:id requires authentication" do
    assert_requires_authentication(:get, api_task_url(@task_to_show))
  end

  test "GET /api/tasks/:id when authenticated returns the task details" do
    get api_task_url(@task_to_show), headers: authenticated_header(@user)
    assert_response :ok
    assert_equal "Show Me Task", json_response['title']
    assert_equal @task_to_show.id, json_response['id']
  end

  test "GET /api/tasks/:id returns not_found for non-existent task" do
    get api_task_url("non_existent_id"), headers: authenticated_header(@user)
    assert_response :not_found
  end

  # --- Get Employee's Today's Tasks ---
  # 라우트: get 'employee/:employee_id/today', to: 'tasks#employee_today'
  test "GET /api/tasks/employee/:employee_id/today requires authentication" do
    assert_requires_authentication(:get, employee_today_api_tasks_url(employee_id: @user.id))
  end

  test "GET /api/tasks/employee/:employee_id/today returns only today's tasks for the employee" do
    # @user_task_today 만 반환되어야 함
    get employee_today_api_tasks_url(employee_id: @user.id), headers: authenticated_header(@user)
    assert_response :ok
    assert_equal 1, json_response.count
    assert_equal @user_task_today.title, json_response.first['title']
  end

  # --- Get Employee's Tasks with Pagination ---
  # 라우트: get 'employee/:employee_id', to: 'tasks#index_by_employee'
  setup do
    # Pagination 테스트를 위한 추가 데이터
    35.times { |i| create(:task, employee: @user, due: Time.zone.today, title: "Paged Task #{i}") }
  end

  test "GET /api/tasks/employee/:employee_id requires authentication" do
    assert_requires_authentication(:get, employee_api_tasks_url(employee_id: @user.id))
  end

  test "GET /api/tasks/employee/:employee_id returns paginated list (first page)" do
    # @user_task_today (1) + @user_task_tomorrow(0, 오늘은 아니므로) + Paged Task(35 for today) = 36 total for today
    # limit 30 이므로 첫 페이지 30개
    get employee_api_tasks_url(employee_id: @user.id), params: { offset: 0 }, headers: authenticated_header(@user)
    assert_response :ok
    assert_equal 30, json_response.count
  end

  test "GET /api/tasks/employee/:employee_id returns next page with offset" do
    # 36개 중 offset 30 이므로 6개 남음
    get employee_api_tasks_url(employee_id: @user.id), params: { offset: 30 }, headers: authenticated_header(@user)
    assert_response :ok
    assert_equal 6, json_response.count
  end

  # --- Get Team's Tasks with Filters and Pagination ---
  # 라우트: get 'team/:team_id', to: 'tasks#index_by_team'
  setup do
    @team_task_cat1_pending = create(:task, employee: @user, category: "Category1", status: "pending", due: Time.zone.now + 1.day)
    @team_task_cat2_done = create(:task, employee: @other_user, category: "Category2", status: "done", due: Time.zone.now + 2.days)
    # @user 와 @other_user 는 @team 에 속해 있음
  end

  test "GET /api/tasks/team/:team_id requires authentication" do
    assert_requires_authentication(:get, team_api_tasks_url(team_id: @team.id))
  end

  test "GET /api/tasks/team/:team_id returns tasks for the team" do
    # @user_task_today, @user_task_tomorrow, @other_user_task_today
    # @team_task_cat1_pending, @team_task_cat2_done
    # 총 5개 Task가 @team 소속 employee들의 Task
    get team_api_tasks_url(team_id: @team.id), params: { offset: 0 }, headers: authenticated_header(@user)
    assert_response :ok
    # 생성된 데이터에 따라 정확한 카운트 확인 필요.
    # @user (3 tasks: today, tomorrow, cat1_pending) + @other_user (2 tasks: today, cat2_done) = 5
    assert_equal 5, json_response.count
  end

  test "GET /api/tasks/team/:team_id filters by category" do
    get team_api_tasks_url(team_id: @team.id), params: { category: "Category1", offset: 0 }, headers: authenticated_header(@user)
    assert_response :ok
    assert_equal 1, json_response.count
    assert_equal "Category1", json_response.first['category']
  end

  test "GET /api/tasks/team/:team_id filters by status" do
    get team_api_tasks_url(team_id: @team.id), params: { status: "done", offset: 0 }, headers: authenticated_header(@user)
    assert_response :ok
    assert_equal 1, json_response.count # @team_task_cat2_done
    assert_equal "done", json_response.first['status']
  end

  test "GET /api/tasks/team/:team_id filters by employee_id" do
    # 컨트롤러에서 params[:employee_id]로 필터링하는 로직이 tasks.where(employee_id: params[:employee_id])로 수정되었다고 가정
    get team_api_tasks_url(team_id: @team.id), params: { employee_id: @user.id, offset: 0 }, headers: authenticated_header(@user)
    assert_response :ok
    # @user 의 task: user_task_today, user_task_tomorrow, team_task_cat1_pending (3개)
    assert_equal 3, json_response.count
    json_response.each do |task_json|
      assert_equal @user.id, task_json['employee_id']
    end
  end

  # --- Get Team's Today's Tasks ---
  # 라우트: get 'team/:team_id/today', to: 'tasks#team_today'
  setup do
    @team_task_for_user_today = create(:task, employee: @user, due: Time.zone.today, title: "User's Team Today Task 2")
    @team_task_for_other_user_today = create(:task, employee: @other_user, due: Time.zone.today, title: "Other User's Team Today Task 2")
  end

  test "GET /api/tasks/team/:team_id/today requires authentication" do
    assert_requires_authentication(:get, team_today_api_tasks_url(team_id: @team.id))
  end

  test "GET /api/tasks/team/:team_id/today returns only today's tasks for the team" do
    # @user_task_today, @other_user_task_today
    # @team_task_for_user_today, @team_task_for_other_user_today
    # 총 4개
    get team_today_api_tasks_url(team_id: @team.id), headers: authenticated_header(@user)
    assert_response :ok
    assert_equal 4, json_response.count
    json_response.each do |task_json|
      task_model = Task.find(task_json['id'])
      assert_equal Time.zone.today, task_model.due.to_date
      assert_includes task_model.employee.teams, @team
    end
  end
end
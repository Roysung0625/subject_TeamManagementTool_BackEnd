#Rails DSL
Rails.application.routes.draw do
  #/api
  namespace :api do
    # チーム関連エンドポイント
    resources :teams, only: %i[create update destroy] do
      # チームメンバー管理
      patch  'management/:team_id', to: 'teams#update_members', on: :collection
      # 特定社員のチーム一覧取得
      get    ':employee_id', to: 'teams#index_by_employee', on: :collection
      get    ':team_id', to: 'teams#index_by_team', on: :collection
    end

    # タスク関連エンドポイント
    resources :tasks, only: %i[create update destroy show] do
      # 特定社員の本日のタスク取得
      get    ':employee_id/today', to: 'tasks#employee_today', on: :collection
      # 特定社員の全タスク取得（フィルタリング: ?category=&status=）
      get    ':employee_id', to: 'tasks#index_by_employee', on: :collection
      # 特定チームの全タスク取得
      get    ':team_id', to: 'tasks#index_by_team', on: :collection
      # 特定チームの本日のタスク取得
      get    ':team_id/today', to: 'tasks#team_today', on: :collection
    end

    # 認証関連エンドポイント
    post   'auth/login', to: 'auth#login'
    post   'auth/register', to: 'auth#register'
    post   'auth/logout', to: 'auth#logout'
  end
end

# to:'employee_teams#index' means "ControllerName#ActionName"
# on::member -> POST /api/employee/:id/teams
# on::collection -> POST /api/employee/teams
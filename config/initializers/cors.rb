# frozen_string_literal: true

#Rails.application(railsのroot object) / .config.middleware(Rack middleware 接近) / .insert_before 0(stackの一番先), Rack::Cors(登録するObjectの名前) do
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  #allow : Rack::CorsのDSL method, どんなoriginに対して 許可を するのか
  # *Domain-Specific Language
  allow do
    origins '*'
    #許可するAPI URL
    resource '*',
             #すべてのリクエスト headerを許可
             #*カスタムheaderの設定が可能
             headers: :any,
             #許可するmethod
             methods: %i[get post put patch delete options head],
             #BrowserがJavaScriptからAccessできるようにする応答headerを指定する部分
             # *CORSでは、基本的にSecurity上の理由から Clientで一部標準 Headerのみ読み取り可能に制限
             expose: %w[Authorization]
  end
end
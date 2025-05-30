# frozen_string_literal: true
module Authenticatable
  # extendはclass(Singleton) methodを組み込む
  # ActiveSupportにConcernを追加
  extend ActiveSupport::Concern

  # includeはinstance methodを組み込み、
  included do
    before_action :authenticate_request!
    attr_reader :current_employee
  end
  #上のBlock内のcodeは、include Authenticatableする各Controller内部で実行
  def authenticate_request!
    header = request.headers['Authorization']
    logger.debug "Authorization Header: #{header.inspect}"
    #if header exists
    token = header.split(' ').last if header
    logger.debug "Extracted Token: #{token.inspect}"
    decoded = JsonWebToken.decode(token)
    logger.debug "decoded: #{decoded.inspect}"
    #payloadの中のuser_idをDBの中で照会
    @current_employee = Employee.find_by(id: decoded[:employee_id]) if decoded
    logger.debug "User ID from Token: #{@current_employee.inspect}"
    #DBで照会ができない場合、エラーメッセージを送信 / status 401
    render json: { error: 'Not Authorized' }, status: :unauthorized unless @current_employee
  end
end

# Railsは大きく次の4つのgem
# -ActiveRecord – DB ORM
# -ActionPack - Controller and View 要請処理
# -ActiveModel – Model共通機能(検証·直列化など)
# -ActiveSupport - 上記の3つのコンポーネントを束ね、Ruby言語自体を拡張するUtility
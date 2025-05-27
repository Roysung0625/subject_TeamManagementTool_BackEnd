class JsonWebToken
  #Class Constant(seed)
  SECRET = ENV['JWT_SECRET_KEY']

  #playload = hash / exp = expire hour
  def self.encode(payload, exp = 24.hours.from_now)
    #満了時間をto_iでintegerに変えた後、tokenに含める
    payload[:exp] = exp.to_i
    Rails.logger.debug "secret: #{SECRET}"
    JWT.encode(payload, SECRET)
  end
  
  def self.decode(token)
    Rails.logger.debug "secret: #{SECRET}"
    #JWT.decodeは[payload, header]の形のlistを返還
    # verify_expiration: true로 만료시간 검증 활성화
    body = JWT.decode(token, SECRET, true, { verify_expiration: true })[0]
    #HashWithIndifferentAccessでwrappingすると、keyをsymbolにしてもstringにしても同じ形で扱う
    HashWithIndifferentAccess.new body
  rescue JWT::ExpiredSignature
    Rails.logger.warn "JWT token has expired"
    nil
  rescue JWT::DecodeError => e
    Rails.logger.warn "JWT decode error: #{e.message}"
    nil
  rescue => e
    Rails.logger.error "Unexpected JWT error: #{e.message}"
    nil
  end
end

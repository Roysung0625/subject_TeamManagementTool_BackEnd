
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
    body = JWT.decode(token, SECRET)[0]
    #HashWithIndifferentAccessでwrappingすると、keyをsymbolにしてもstringにしても同じ形で扱う
    HashWithIndifferentAccess.new body
  rescue
    nil
  end
end

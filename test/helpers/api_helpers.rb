module ApiHelpers
  def json_response
    JSON.parse(response.body)
  end

  def authenticated_header(employee)
    token = JsonWebToken.encode(employee_id: employee.id)
    { 'Authorization': "Bearer #{token}" }
  end
end

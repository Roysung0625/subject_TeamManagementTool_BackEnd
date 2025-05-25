# test/factories/employees.rb
FactoryBot.define do
  factory :employee do
    sequence(:name) { |n| "Employee #{n}" }
    password { "password123" }
    password_confirmation { password } # password 속성의 값을 그대로 사용
    role { "Employee" }

    trait :admin do
      role { "Admin" }
    end
  end
end
# test/factories/employees.rb
FactoryBot.define do
  factory :employee do
    sequence(:name) { |n| "Employee #{n}" }
    password { "password" }
    password_confirmation { "password" }
    role { "Employee" }

    trait :admin do
      role { "Admin" }
    end
  end
end
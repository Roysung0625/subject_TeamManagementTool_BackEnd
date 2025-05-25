FactoryBot.define do
  factory :task do
    sequence(:title) { |n| "Sample Task Title #{n}" }
    association :employee
    status { Task.statuses.keys.sample }
    category { "General Task" }
    detail { "This is a sample task detail." }
    due { Time.zone.now + 1.day }
  end
end
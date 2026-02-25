FactoryBot.define do
  factory :rephrase do
    content { "言い換えテキスト" }
    association :category

    trait :invalid do
      content { nil }
    end

    trait :too_long do
      content { "あ" * 301 }
    end
  end
end

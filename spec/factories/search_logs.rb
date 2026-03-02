FactoryBot.define do
  factory :search_log do
    query { "検索キーワード" }
    converted_text { "変換後テキスト" }
    association :category
    hit_type { :exact }
    safety_mode_applied { false }

    trait :invalid do
      query { nil }
      converted_text { nil }
      hit_type { nil }
    end

    trait :blank_query do
      query { nil }
    end

    trait :blank_converted_text do
      converted_text { nil }
    end

    trait :too_long do
      converted_text { "あ" * 301 }
    end

    trait :blank_hit_type do
      hit_type { "" }
    end

    trait :without_category do
      category { nil }
    end
  end
end

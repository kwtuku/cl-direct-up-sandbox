FactoryBot.define do
  factory :article do
    title { 'title' }
    body { 'body' }

    trait :with_an_image do
      after(:create) do |article|
        create(:image, article: article)
        article.reload
      end
    end

    trait :with_3_images do
      after(:create) do |article|
        create_list(:image, 3, article: article)
        article.reload
      end
    end

    trait :with_9_images do
      after(:create) do |article|
        create_list(:image, 9, article: article)
        article.reload
      end
    end

    trait :with_10_images do
      after(:create) do |article|
        create_list(:image, 10, article: article)
        article.reload
      end
    end
  end
end

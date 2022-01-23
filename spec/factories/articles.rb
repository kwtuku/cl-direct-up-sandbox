FactoryBot.define do
  factory :article do
    title { Faker::Lorem.word }
    body { Faker::Lorem.paragraph(sentence_count: 10) }

    trait :with_images do
      transient { images_count { 2 } }

      after(:create) do |article, evaluator|
        create_list(:image, evaluator.images_count, article: article)
        article.reload.images.shuffle.each.with_index(1) { |image, i| image.update(position: i) }
        article.reload
      end
    end
  end
end

FactoryBot.define do
  factory :image do
    example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
    cl_id { Rack::Test::UploadedFile.new(example_image) }
    association :article
  end
end

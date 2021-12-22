require 'rails_helper'

RSpec.describe Image, type: :model do
  describe 'validations' do
    let(:example_image) { Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}") }

    context 'when the article does not have images' do
      it 'is valid' do
        article = create(:article)
        image = article.images.new(cl_id: Rack::Test::UploadedFile.new(example_image))
        expect(image).to be_valid
      end
    end

    context 'when the article has an image' do
      it 'is valid' do
        article = create(:article, :with_an_image)
        image = article.images.new(cl_id: Rack::Test::UploadedFile.new(example_image))
        expect(image).to be_valid
      end
    end

    context 'when the article has 9 images' do
      it 'is valid' do
        article = create(:article, :with_9_images)
        image = article.images.new(cl_id: Rack::Test::UploadedFile.new(example_image))
        expect(image).to be_valid
      end
    end

    context 'when the article has 10 images' do
      it 'is invalid' do
        article = create(:article, :with_10_images)
        image = article.images.new(cl_id: Rack::Test::UploadedFile.new(example_image))
        expect(image).to be_invalid
        expect(image.errors).to be_of_kind(:base, :too_many_images)
      end
    end
  end
end

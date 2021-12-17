require 'rails_helper'

RSpec.describe Image, type: :model do
  describe 'validations' do
    context 'when the article does not have images' do
      it 'is valid' do
        article = create(:article)
        image = build_stubbed(:image, article: article)
        expect(image).to be_valid
      end
    end

    context 'when the article has an image' do
      it 'is valid' do
        article = create(:article, :with_an_image)
        image = build_stubbed(:image, article: article)
        expect(image).to be_valid
      end
    end

    context 'when the article has 10 images' do
      it 'is invalid' do
        article = create(:article, :with_10_images)
        image = build_stubbed(:image, article: article)
        expect(image).to be_invalid
        expect(image.errors).to be_of_kind(:base, :too_many_images)
      end
    end
  end
end

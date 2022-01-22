require 'rails_helper'

RSpec.describe Article, type: :model do
  describe 'has_many :images, -> { order(position: :ASC) }' do
    let!(:article) do
      article = create(:article, :with_an_image)
      first_image = article.images.first
      first_image.update(position: 1)
      article
    end
    let!(:first_image) { article.images.first }
    let!(:third_image) { create(:image, position: 3, article: article) }
    let!(:second_image) { create(:image, position: 2, article: article) }

    it 'has images ordered by position' do
      expect(article.images).to eq [first_image, second_image, third_image]
    end

    it 'changes order' do
      expect do
        first_image.update(position: 2)
        second_image.update(position: 1)
      end.to change { article.reload.images }.from([first_image, second_image, third_image])
        .to([second_image, first_image, third_image])
    end
  end
end

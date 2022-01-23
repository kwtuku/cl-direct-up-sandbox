require 'rails_helper'

RSpec.describe Article, type: :model do
  describe 'has_many :images, -> { order(position: :ASC) }' do
    let!(:article) { create(:article, :with_images, images_count: 3) }
    let(:first_image) { article.images.find_by(position: 1) }
    let(:second_image) { article.images.find_by(position: 2) }
    let(:third_image) { article.images.find_by(position: 3) }

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

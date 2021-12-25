require 'rails_helper'

RSpec.describe 'Api::V0::Images', type: :request do
  describe 'DELETE /api/v0/articles/:article_id/images/:id' do
    context 'when an article has 2 images' do
      let!(:article) { create(:article, :with_an_image) }
      let!(:image) { create(:image, article: article) }

      it 'returns ok' do
        delete api_v0_article_image_path(article, image)
        expect(response).to have_http_status(:ok)
      end

      it 'decreases image count' do
        expect { delete api_v0_article_image_path(article, image) }.to change(Image, :count).by(-1)
      end
    end

    context 'when an article has a image' do
      let!(:article) { create(:article) }
      let!(:image) { create(:image, article: article) }

      it 'returns ok' do
        delete api_v0_article_image_path(article, image)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not decrease image count' do
        expect do
          delete api_v0_article_image_path(article, image)
        end.to change(Image, :count).by(0)
      end
    end
  end
end

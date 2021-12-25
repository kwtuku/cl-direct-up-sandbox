require 'rails_helper'

RSpec.describe 'Images', type: :request do
  describe 'DELETE /articles/:article_id/images/:id' do
    context 'when an article has 2 images' do
      let!(:article) { create(:article, :with_an_image) }
      let!(:image) { create(:image, article: article) }

      it 'returns found' do
        delete article_image_path(article, image)
        expect(response).to have_http_status(:found)
      end

      it 'redirects to article url' do
        delete article_image_path(article, image)
        expect(response).to redirect_to article_url(article)
      end

      it 'decreases image count' do
        expect do
          delete article_image_path(article, image)
        end.to change(Image, :count).by(-1)
      end
    end

    context 'when an article has a image' do
      let!(:article) { create(:article) }
      let!(:image) { create(:image, article: article) }

      it 'returns found' do
        delete article_image_path(article, image)
        expect(response).to have_http_status(:found)
      end

      it 'redirects to article url' do
        delete article_image_path(article, image)
        expect(response).to redirect_to article_url(article)
      end

      it 'does not decrease image count' do
        expect do
          delete article_image_path(article, image)
        end.to change(Image, :count).by(0)
      end
    end
  end
end

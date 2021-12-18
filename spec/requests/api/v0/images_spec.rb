require 'rails_helper'

RSpec.describe 'Api::V0::Images', type: :request do
  describe 'DELETE /api/v0/articles/:article_id/images/:id' do
    let!(:article) { create(:article) }
    let!(:image) { create(:image, article: article) }

    it 'returns ok' do
      delete api_v0_article_image_path(article, image)
      expect(response).to have_http_status(:ok)
    end

    it 'decreases image count' do
      expect { delete api_v0_article_image_path(article, image) }.to change(Image, :count).by(-1)
    end
  end
end

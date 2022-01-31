require 'rails_helper'

RSpec.describe 'Articles', type: :request do
  describe 'GET /articles' do
    it 'returns ok' do
      create_list(:article, 2, :with_images)
      get articles_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /articles/:id' do
    it 'returns ok' do
      article = create(:article, :with_images)
      get article_path(article)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /articles/new' do
    it 'returns ok' do
      get new_article_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /articles/:id/edit' do
    it 'returns ok' do
      article = create(:article, :with_images)
      get edit_article_path(article)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'DELETE /articles/:id' do
    let!(:article) { create(:article, :with_images) }

    it 'returns found' do
      delete article_path(article)
      expect(response).to have_http_status(:found)
    end

    it 'redirects to articles_url' do
      delete article_path(article)
      expect(response).to redirect_to articles_url
    end

    it 'decreases article count by 1' do
      expect do
        delete article_path(article)
      end.to change(Article, :count).by(-1)
    end
  end
end

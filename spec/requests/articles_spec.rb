require 'rails_helper'

RSpec.describe 'Articles', type: :request do
  describe 'GET /articles' do
    it 'returns ok' do
      create_list(:article, 2, :with_an_image)
      get articles_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /articles/:id' do
    it 'returns ok' do
      article = create(:article, :with_an_image)
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
      article = create(:article, :with_an_image)
      get edit_article_path(article)
      expect(response).to have_http_status(:ok)
    end
  end
end

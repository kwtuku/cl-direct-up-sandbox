require 'rails_helper'

RSpec.describe 'Articles', type: :request do
  def image_attributes(images_count)
    image_attributes = {}
    images_count.times do |i|
      example_image_path = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
      random_number = SecureRandom.random_number(1 << 64)

      image_attributes[random_number] = {
        'cl_id' => Rack::Test::UploadedFile.new(example_image_path), 'position' => (i + 1).to_s
      }
    end
    image_attributes
  end

  def mock_cl_ids(images_count)
    cl_ids = []
    images_count.times do
      version = SecureRandom.random_number(1 << 32)
      public_id = SecureRandom.hex(10)
      extension = %w[jpg jpeg png webp].sample
      signature = SecureRandom.hex(10)
      cl_ids << "image/upload/v#{version}/#{public_id}.#{extension}##{signature}"
    end
    cl_ids
  end

  def mock_image_attributes(mock_cl_ids)
    image_attributes = {}
    mock_cl_ids.each.with_index(1) do |cl_id, i|
      image_attributes[SecureRandom.random_number(1 << 64)] = { 'cl_id' => cl_id, 'position' => i.to_s }
    end
    image_attributes
  end

  describe 'POST /articles' do
    context 'when params has title, body and 1 cl_id' do
      let(:params) { { article: { **attributes_for(:article), image_attributes: image_attributes(1) } } }

      it 'returns found' do
        post articles_path, params: params
        expect(response).to have_http_status(:found)
      end

      it 'redirects to the article show page' do
        post articles_path, params: params
        expect(response).to redirect_to article_url(Article.last)
      end

      it 'increases article count by 1' do
        expect do
          post articles_path, params: params
        end.to change(Article, :count).by(1)
      end

      it 'increases image count by 1' do
        expect do
          post articles_path, params: params
        end.to change(Image, :count).by(1)
      end
    end

    context 'when params has title, body and 10 cl_id' do
      let(:params) { { article: { **attributes_for(:article), image_attributes: image_attributes(10) } } }

      it 'returns found' do
        post articles_path, params: params
        expect(response).to have_http_status(:found)
      end

      it 'redirects to the article show page' do
        post articles_path, params: params
        expect(response).to redirect_to article_url(Article.last)
      end

      it 'increases article count by 1' do
        expect do
          post articles_path, params: params
        end.to change(Article, :count).by(1)
      end

      it 'increases image count by 10' do
        expect do
          post articles_path, params: params
        end.to change(Image, :count).by(10)
      end
    end

    context 'when params has title, body and 11 cl_id' do
      let(:cl_ids) { mock_cl_ids(11) }
      let(:params) { { article: { **attributes_for(:article), image_attributes: mock_image_attributes(cl_ids) } } }

      it 'returns ok' do
        post articles_path, params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not increase article count' do
        expect do
          post articles_path, params: params
        end.to change(Article, :count).by(0)
      end

      it 'does not increase image count' do
        expect do
          post articles_path, params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 1 error message in body' do
        post articles_path, params: params
        expect(response.body).to include '1件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include '記事の画像は10枚以下にしてください'
      end

      it 'has 11 cl_id caches in body' do
        post articles_path, params: params
        cl_ids.each do |cl_id|
          expect(response.body).to include "value=\"#{cl_id}\""
        end
      end
    end

    context 'when params does not have title, body and image_attributes' do
      let(:params) { { article: { title: '', body: '' } } }

      it 'returns ok' do
        post articles_path, params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not increase article count' do
        expect do
          post articles_path, params: params
        end.to change(Article, :count).by(0)
      end

      it 'does not increase image count' do
        expect do
          post articles_path, params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 3 error messages in body' do
        post articles_path, params: params
        expect(response.body).to include '3件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include 'タイトルを入力してください'
        expect(response.body).to include '本文を入力してください'
        expect(response.body).to include '記事には画像が1枚以上必要です'
      end
    end

    context 'when params has only title and body' do
      let(:params) { { article: attributes_for(:article) } }

      it 'returns ok' do
        post articles_path, params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not increase article count' do
        expect do
          post articles_path, params: params
        end.to change(Article, :count).by(0)
      end

      it 'does not increase image count' do
        expect do
          post articles_path, params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 1 error message in body' do
        post articles_path, params: params
        expect(response.body).to include '1件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include '記事には画像が1枚以上必要です'
      end
    end

    context 'when params has only 1 cl_id' do
      let(:cl_ids) { mock_cl_ids(1) }
      let(:params) { { article: { title: '', body: '', image_attributes: mock_image_attributes(cl_ids) } } }

      it 'returns ok' do
        post articles_path, params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not increase article count' do
        expect do
          post articles_path, params: params
        end.to change(Article, :count).by(0)
      end

      it 'does not increase image count' do
        expect do
          post articles_path, params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 2 error messages in body' do
        post articles_path, params: params
        expect(response.body).to include '2件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include 'タイトルを入力してください'
        expect(response.body).to include '本文を入力してください'
      end

      it 'has 1 cl_id cache in body' do
        post articles_path, params: params
        cl_ids.each do |cl_id|
          expect(response.body).to include "value=\"#{cl_id}\""
        end
      end
    end

    context 'when params has only 10 cl_id' do
      let(:cl_ids) { mock_cl_ids(10) }
      let(:params) { { article: { title: '', body: '', image_attributes: mock_image_attributes(cl_ids) } } }

      it 'returns ok' do
        post articles_path, params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not increase article count' do
        expect do
          post articles_path, params: params
        end.to change(Article, :count).by(0)
      end

      it 'does not increase image count' do
        expect do
          post articles_path, params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 2 error messages in body' do
        post articles_path, params: params
        expect(response.body).to include '2件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include 'タイトルを入力してください'
        expect(response.body).to include '本文を入力してください'
      end

      it 'has 10 cl_id caches in body' do
        post articles_path, params: params
        cl_ids.each do |cl_id|
          expect(response.body).to include "value=\"#{cl_id}\""
        end
      end
    end

    context 'when params has only 11 cl_id' do
      let(:cl_ids) { mock_cl_ids(11) }
      let(:params) { { article: { title: '', body: '', image_attributes: mock_image_attributes(cl_ids) } } }

      it 'returns ok' do
        post articles_path, params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not increase article count' do
        expect do
          post articles_path, params: params
        end.to change(Article, :count).by(0)
      end

      it 'does not increase image count' do
        expect do
          post articles_path, params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 3 error messages in body' do
        post articles_path, params: params
        expect(response.body).to include '3件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include 'タイトルを入力してください'
        expect(response.body).to include '本文を入力してください'
        expect(response.body).to include '記事の画像は10枚以下にしてください'
      end

      it 'has 11 cl_id caches in body' do
        post articles_path, params: params
        cl_ids.each do |cl_id|
          expect(response.body).to include "value=\"#{cl_id}\""
        end
      end
    end
  end
end

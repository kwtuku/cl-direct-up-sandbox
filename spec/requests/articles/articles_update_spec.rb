require 'rails_helper'

RSpec.describe 'Articles', type: :request do
  def example_image_path
    Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
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

  def add_cl_ids(image_attributes, images_count)
    images_count.times do |i|
      image_attributes[SecureRandom.random_number(1 << 64)] = {
        'cl_id' => Rack::Test::UploadedFile.new(example_image_path), 'position' => (i + 1).to_s
      }
    end
  end

  def add_mock_cl_ids(image_attributes, mock_cl_ids)
    mock_cl_ids.each.with_index(1) do |cl_id, i|
      image_attributes[SecureRandom.random_number(1 << 64)] = { 'cl_id' => cl_id, 'position' => i.to_s }
    end
  end

  describe 'PATCH /articles/:id' do
    context 'when editing article with valid title and body' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1, title: 'title', body: 'body') }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        { article: { title: 'new title', body: 'new body', image_attributes: image_attributes } }
      end

      it 'returns found' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:found)
      end

      it 'redirects to the article show page' do
        patch article_path(existing_article), params: params
        expect(response).to redirect_to article_url(existing_article)
      end

      it 'changes title' do
        expect do
          patch article_path(existing_article), params: params
        end.to change { existing_article.reload.title }.from('title').to('new title')
      end

      it 'changes body' do
        expect do
          patch article_path(existing_article), params: params
        end.to change { existing_article.reload.body }.from('body').to('new body')
      end
    end

    context 'when editing position' do
      let!(:existing_article) { create(:article, :with_images, images_count: 3) }
      let(:first_image) { existing_article.images.find_by(position: 1) }
      let(:second_image) { existing_article.images.find_by(position: 2) }
      let(:third_image) { existing_article.images.find_by(position: 3) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        image_attributes[first_image.id]['position'] = '2'
        image_attributes[second_image.id]['position'] = '1'
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns found' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:found)
      end

      it 'redirects to the article show page' do
        patch article_path(existing_article), params: params
        expect(response).to redirect_to article_url(existing_article)
      end

      it 'changes images order' do
        expect do
          patch article_path(existing_article), params: params
        end.to change { existing_article.reload.images }.from([first_image, second_image, third_image])
          .to([second_image, first_image, third_image])
      end
    end

    context 'when an article exists with 1 image and adding 1 image' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        add_cl_ids(image_attributes, 1)
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns found' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:found)
      end

      it 'redirects to the article show page' do
        patch article_path(existing_article), params: params
        expect(response).to redirect_to article_url(existing_article)
      end

      it 'increases image count by 1' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(1)
      end
    end

    context 'when  an article exists with 1 image and adding 9 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        add_cl_ids(image_attributes, 9)
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns found' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:found)
      end

      it 'redirects to the article show page' do
        patch article_path(existing_article), params: params
        expect(response).to redirect_to article_url(existing_article)
      end

      it 'increases image count by 9' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(9)
      end
    end

    context 'when an article exists with 1 image and adding 10 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:cl_ids) { mock_cl_ids(10) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        add_mock_cl_ids(image_attributes, cl_ids)
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns ok' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not increase image count' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 1 error message in body' do
        patch article_path(existing_article), params: params
        expect(response.body).to include '1件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include '記事の画像は10枚以下にしてください'
      end

      it 'has 10 cl_id caches in body' do
        patch article_path(existing_article), params: params
        cl_ids.each do |cl_id|
          expect(response.body).to include "value=\"#{cl_id}\""
        end
      end
    end

    context 'when an article exists with 1 image and deleting 1 image' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        image_attributes[existing_article.image_ids.first]['_destroy'] = 'true'
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns ok' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not decrease image count' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 1 error message in body' do
        patch article_path(existing_article), params: params
        expect(response.body).to include '1件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include '記事には画像が1枚以上必要です'
      end
    end

    context 'when an article exists with 1 image and deleting 1 image and adding 1 image' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        image_attributes[existing_article.image_ids.first]['_destroy'] = 'true'
        add_cl_ids(image_attributes, 1)
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns found' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:found)
      end

      it 'redirects to the article show page' do
        patch article_path(existing_article), params: params
        expect(response).to redirect_to article_url(existing_article)
      end

      it 'does not change image count' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(0)
      end

      it 'changes image_ids' do
        destroying_image_ids = existing_article.image_ids
        patch article_path(existing_article), params: params
        expect(existing_article.reload.image_ids).not_to match_array destroying_image_ids
      end
    end

    context 'when an article exists with 1 image and deleting 1 image and adding 10 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        image_attributes[existing_article.image_ids.first]['_destroy'] = 'true'
        add_cl_ids(image_attributes, 10)
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns found' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:found)
      end

      it 'redirects to the article show page' do
        patch article_path(existing_article), params: params
        expect(response).to redirect_to article_url(existing_article)
      end

      it 'changes image count from 1 to 10' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).from(1).to(10)
      end
    end

    context 'when an article exists with 1 image and deleting 1 image and adding 11 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:cl_ids) { mock_cl_ids(11) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        image_attributes[existing_article.image_ids.first]['_destroy'] = 'true'
        add_mock_cl_ids(image_attributes, cl_ids)
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns ok' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not increase image count' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 1 error message in body' do
        patch article_path(existing_article), params: params
        expect(response.body).to include '1件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include '記事の画像は10枚以下にしてください'
      end

      it 'has 11 cl_id caches in body' do
        patch article_path(existing_article), params: params
        cl_ids.each do |cl_id|
          expect(response.body).to include "value=\"#{cl_id}\""
        end
      end
    end

    context 'when an article exists with 10 images and adding 1 image' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:cl_ids) { mock_cl_ids(1) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        add_mock_cl_ids(image_attributes, cl_ids)
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns ok' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not increase image count' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 1 error message in body' do
        patch article_path(existing_article), params: params
        expect(response.body).to include '1件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include '記事の画像は10枚以下にしてください'
      end

      it 'has 1 cl_id cache in body' do
        patch article_path(existing_article), params: params
        expect(response.body).to include "value=\"#{cl_ids.first}\""
      end
    end

    context 'when an article exists with 10 images and deleting 1 image' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        image_attributes[existing_article.image_ids.sample]['_destroy'] = 'true'
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns found' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:found)
      end

      it 'redirects to the article show page' do
        patch article_path(existing_article), params: params
        expect(response).to redirect_to article_url(existing_article)
      end

      it 'decreases image count by 1' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(-1)
      end
    end

    context 'when an article exists with 10 images and deleting 1 image and adding 1 image' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        image_attributes[existing_article.image_ids.sample]['_destroy'] = 'true'
        add_cl_ids(image_attributes, 1)
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns found' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:found)
      end

      it 'redirects to the article show page' do
        patch article_path(existing_article), params: params
        expect(response).to redirect_to article_url(existing_article)
      end

      it 'does not change image count' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(0)
      end

      it 'changes image_ids' do
        destroying_image_ids = existing_article.image_ids
        patch article_path(existing_article), params: params
        expect(existing_article.reload.image_ids).not_to match_array destroying_image_ids
      end
    end

    context 'when an article exists with 10 images and deleting 1 image and adding 2 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:cl_ids) { mock_cl_ids(2) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        image_attributes[existing_article.image_ids.sample]['_destroy'] = 'true'
        add_mock_cl_ids(image_attributes, cl_ids)
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns ok' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not increase image count' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 1 error message in body' do
        patch article_path(existing_article), params: params
        expect(response.body).to include '1件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include '記事の画像は10枚以下にしてください'
      end

      it 'has 2 cl_id caches in body' do
        patch article_path(existing_article), params: params
        cl_ids.each do |cl_id|
          expect(response.body).to include "value=\"#{cl_id}\""
        end
      end
    end

    context 'when an article exists with 10 images and deleting 9 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        existing_article.image_ids.sample(9).each { |image_id| image_attributes[image_id]['_destroy'] = 'true' }
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns found' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:found)
      end

      it 'redirects to the article show page' do
        patch article_path(existing_article), params: params
        expect(response).to redirect_to article_url(existing_article)
      end

      it 'decreases image count by 9' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(-9)
      end
    end

    context 'when an article exists wit 10 images and deleting 9 images and adding 1 image' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        existing_article.image_ids.sample(9).each { |image_id| image_attributes[image_id]['_destroy'] = 'true' }
        add_cl_ids(image_attributes, 1)
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns found' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:found)
      end

      it 'redirects to the article show page' do
        patch article_path(existing_article), params: params
        expect(response).to redirect_to article_url(existing_article)
      end

      it 'changes image count from 10 to 2' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).from(10).to(2)
      end
    end

    context 'when an article exists wit 10 images and deleting 9 images and adding 9 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        existing_article.image_ids.sample(9).each { |image_id| image_attributes[image_id]['_destroy'] = 'true' }
        add_cl_ids(image_attributes, 9)
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns found' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:found)
      end

      it 'redirects to the article show page' do
        patch article_path(existing_article), params: params
        expect(response).to redirect_to article_url(existing_article)
      end

      it 'does not change image count' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(0)
      end

      it 'changes image_ids' do
        destroying_image_ids = existing_article.image_ids
        patch article_path(existing_article), params: params
        expect(existing_article.reload.image_ids).not_to match_array destroying_image_ids
      end
    end

    context 'when an article exists wit 10 images and deleting 9 images and adding 10 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:cl_ids) { mock_cl_ids(10) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        existing_article.image_ids.sample(9).each { |image_id| image_attributes[image_id]['_destroy'] = 'true' }
        add_mock_cl_ids(image_attributes, cl_ids)
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns ok' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not increase image count' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 1 error message in body' do
        patch article_path(existing_article), params: params
        expect(response.body).to include '1件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include '記事の画像は10枚以下にしてください'
      end

      it 'has 10 cl_id caches in body' do
        patch article_path(existing_article), params: params
        cl_ids.each do |cl_id|
          expect(response.body).to include "value=\"#{cl_id}\""
        end
      end
    end

    context 'when an article exists with 10 images and deleting 10 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        existing_article.image_ids.each { |image_id| image_attributes[image_id]['_destroy'] = 'true' }
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns ok' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not decrease image count' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 1 error message in body' do
        patch article_path(existing_article), params: params
        expect(response.body).to include '1件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include '記事には画像が1枚以上必要です'
      end
    end

    context 'when an article exists wit 10 images and deleting 10 images and adding 1 image' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        existing_article.image_ids.each { |image_id| image_attributes[image_id]['_destroy'] = 'true' }
        add_cl_ids(image_attributes, 1)
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns found' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:found)
      end

      it 'redirects to the article show page' do
        patch article_path(existing_article), params: params
        expect(response).to redirect_to article_url(existing_article)
      end

      it 'changes image count from 10 to 1' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).from(10).to(1)
      end
    end

    context 'when an article exists wit 10 images and deleting 10 images and adding 10 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        existing_article.image_ids.each { |image_id| image_attributes[image_id]['_destroy'] = 'true' }
        add_cl_ids(image_attributes, 10)
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns found' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:found)
      end

      it 'redirects to the article show page' do
        patch article_path(existing_article), params: params
        expect(response).to redirect_to article_url(existing_article)
      end

      it 'does not change image count' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(0)
      end

      it 'changes image_ids' do
        destroying_image_ids = existing_article.image_ids
        patch article_path(existing_article), params: params
        expect(existing_article.reload.image_ids).not_to match_array destroying_image_ids
      end
    end

    context 'when an article exists wit 10 images and deleting 10 images and adding 11 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:cl_ids) { mock_cl_ids(11) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        existing_article.image_ids.each { |image_id| image_attributes[image_id]['_destroy'] = 'true' }
        add_mock_cl_ids(image_attributes, cl_ids)
        { article: { **attributes_for(:article), image_attributes: image_attributes } }
      end

      it 'returns ok' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not increase image count' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 1 error message in body' do
        patch article_path(existing_article), params: params
        expect(response.body).to include '1件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include '記事の画像は10枚以下にしてください'
      end

      it 'has 11 cl_id caches in body' do
        patch article_path(existing_article), params: params
        cl_ids.each do |cl_id|
          expect(response.body).to include "value=\"#{cl_id}\""
        end
      end
    end

    context 'when title is blank and too many images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:cl_ids) { mock_cl_ids(11) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        add_mock_cl_ids(image_attributes, cl_ids)
        { article: { **attributes_for(:article, title: ''), image_attributes: image_attributes } }
      end

      it 'returns ok' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not increase image count' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 2 error messages in body' do
        patch article_path(existing_article), params: params
        expect(response.body).to include '2件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include 'タイトルを入力してください'
        expect(response.body).to include '記事の画像は10枚以下にしてください'
      end

      it 'has 11 cl_id caches in body' do
        patch article_path(existing_article), params: params
        cl_ids.each do |cl_id|
          expect(response.body).to include "value=\"#{cl_id}\""
        end
      end
    end

    context 'when body is blank and no images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:params) do
        image_attributes = ArticleForm.new(article: existing_article).image_attributes
        image_attributes[existing_article.image_ids.sample]['_destroy'] = 'true'
        { article: { **attributes_for(:article, body: ''), image_attributes: image_attributes } }
      end

      it 'returns ok' do
        patch article_path(existing_article), params: params
        expect(response).to have_http_status(:ok)
      end

      it 'does not change image count' do
        expect do
          patch article_path(existing_article), params: params
        end.to change(Image, :count).by(0)
      end

      it 'has 2 error messages in body' do
        patch article_path(existing_article), params: params
        expect(response.body).to include '2件のエラーが発生したため記事は保存されませんでした'
        expect(response.body).to include '本文を入力してください'
        expect(response.body).to include '記事には画像が1枚以上必要です'
      end
    end
  end
end

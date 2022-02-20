require 'rails_helper'

RSpec.describe ArticleForm, type: :model do
  def example_image_path
    Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
  end

  def random_number
    SecureRandom.random_number(1 << 64)
  end

  describe '#sanitized_image_attributes_collection' do
    context 'when new article with no image_attributes' do
      it 'returns []' do
        attributes = { **attributes_for(:article), image_attributes: nil }
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.sanitized_image_attributes_collection).to eq []
      end
    end

    context 'when new article and image_attributes has other article image_id' do
      it 'removes other article image_id' do
        other_article_image_id = create(:image).id
        image_attributes = {
          Time.now.to_i.to_s => { 'cl_id' => 'image_path' },
          random_number => { 'id' => other_article_image_id.to_s, '_destroy' => 'true' }
        }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.sanitized_image_attributes_collection.size).to eq 1
        sanitized_image_ids = article_form.sanitized_image_attributes_collection.map { |attrs| attrs['id'] }.compact
        expect(sanitized_image_ids).not_to include other_article_image_id
      end
    end

    context 'when existing article and image_attributes has other article image_id' do
      it 'removes other article image_id' do
        other_article_image_id = create(:image).id
        existing_article = create(:article, :with_images, images_count: 1)
        image_attributes = described_class.new(article: existing_article).image_attributes
        image_attributes[Time.now.to_i.to_s] = { 'cl_id' => 'image_path' }
        image_attributes[random_number] = { 'id' => other_article_image_id.to_s, '_destroy' => 'true' }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: existing_article)
        expect(article_form.sanitized_image_attributes_collection.size).to eq 2
        sanitized_image_ids = article_form.sanitized_image_attributes_collection.map { |attrs| attrs['id'] }.compact
        expect(sanitized_image_ids).not_to include other_article_image_id
      end
    end

    context 'when existing article and image_attributes has invalid attributes' do
      it 'removes invalid attributes' do
        existing_article = create(:article, :with_images, images_count: 3)
        image_attributes = described_class.new(article: existing_article).image_attributes
        image_ids = existing_article.image_ids
        image_attributes[image_ids.first] = { 'position' => 2, '_destroy' => 'true' }
        image_attributes[image_ids.second] = { 'id' => image_ids.second, '_destroy' => 'false' }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: existing_article)
        expect(article_form.sanitized_image_attributes_collection.size).to eq 1
      end
    end
  end

  describe '#destroying_image_ids' do
    context 'when new article with no images' do
      it 'returns []' do
        attributes = { **attributes_for(:article), image_attributes: nil }
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.destroying_image_ids).to eq []
      end
    end

    context 'when new article and adding 1 image' do
      it 'returns []' do
        image_attributes = { Time.now.to_i.to_s => { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.destroying_image_ids).to eq []
      end
    end

    context 'when an article exists without destroying images' do
      it 'returns []' do
        existing_article = create(:article, :with_images, images_count: 1)
        image_attributes = described_class.new(article: existing_article).image_attributes
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: existing_article)
        expect(article_form.destroying_image_ids).to eq []
      end
    end

    context 'when an article exists and destroying images' do
      let(:existing_article) { create(:article, :with_images, images_count: 3) }

      it 'returns an array of destroying_image_id' do
        destroying_image_id = existing_article.image_ids.sample
        image_attributes = described_class.new(article: existing_article).image_attributes
        image_attributes[destroying_image_id]['_destroy'] = 'true'
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: existing_article)
        expect(article_form.destroying_image_ids).to eq [destroying_image_id]
      end

      it 'returns an array of destroying_image_ids' do
        destroying_image_ids = existing_article.image_ids.sample(2)
        image_attributes = described_class.new(article: existing_article).image_attributes
        destroying_image_ids.each { |id| image_attributes[id]['_destroy'] = 'true' }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: existing_article)
        expect(article_form.destroying_image_ids).to match_array destroying_image_ids
      end
    end
  end

  describe '#save' do
    context 'when new article with blank title' do
      let(:article_form) do
        attributes = attributes_for(:article, title: nil)
        described_class.new(attributes, article: Article.new)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has the error of title blank' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:title, :blank)
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end
    end

    context 'when new article with blank body' do
      let(:article_form) do
        attributes = attributes_for(:article, body: nil)
        described_class.new(attributes, article: Article.new)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has the error of body blank' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:body, :blank)
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end
    end

    context 'when new article with no images' do
      let(:article_form) do
        attributes = { **attributes_for(:article), image_attributes: nil }
        described_class.new(attributes, article: Article.new)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has the error of require_images' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:base, :require_images)
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'does not increase image count' do
        expect { article_form.save }.to change(Image, :count).by(0)
      end
    end

    context 'when new article with 1 image' do
      let(:article_form) do
        image_attributes = { Time.now.to_i.to_s => { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: Article.new)
      end

      it 'returns true' do
        expect(article_form.save).to be_truthy
      end

      it 'increases article count by 1' do
        expect { article_form.save }.to change(Article, :count).by(1)
      end

      it 'increases image count by 1' do
        expect { article_form.save }.to change(Image, :count).by(1)
      end
    end

    context 'when new article with 10 images' do
      let(:article_form) do
        image_attributes = {}
        10.times { image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: Article.new)
      end

      it 'returns true' do
        expect(article_form.save).to be_truthy
      end

      it 'increases article count by 1' do
        expect { article_form.save }.to change(Article, :count).by(1)
      end

      it 'increases image count by 10' do
        expect { article_form.save }.to change(Image, :count).by(10)
      end
    end

    context 'when new article with 11 images' do
      let(:article_form) do
        image_attributes = {}
        11.times { image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: Article.new)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has the error of too_many_images' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:base, :too_many_images)
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'does not increase image count' do
        expect { article_form.save }.to change(Image, :count).by(0)
      end
    end

    context 'when an article exists with 1 image without adding images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns true' do
        expect(article_form.save).to be_truthy
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'does not increase image count' do
        expect { article_form.save }.to change(Image, :count).by(0)
      end
    end

    context 'when an article exists with 1 image and adding 1 image' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        image_attributes[Time.now.to_i.to_s] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns true' do
        expect(article_form.save).to be_truthy
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'increases image count by 1' do
        expect { article_form.save }.to change(Image, :count).by(1)
      end
    end

    context 'when an article exists with 1 image and adding 9 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        9.times { image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns true' do
        expect(article_form.save).to be_truthy
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'increases image count by 9' do
        expect { article_form.save }.to change(Image, :count).by(9)
      end
    end

    context 'when an article exists with 1 image and adding 10 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        10.times { image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has the error of too_many_images' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:base, :too_many_images)
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'does not increase image count' do
        expect { article_form.save }.to change(Image, :count).by(0)
      end
    end

    context 'when an article exists with 1 image and destroying 1 image' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        image_attributes[existing_article.image_ids.first]['_destroy'] = 'true'
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has the error of require_images' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:base, :require_images)
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'does not decrease image count' do
        expect { article_form.save }.to change(Image, :count).by(0)
      end
    end

    context 'when an article exists with 1 image and destroying 1 image and adding 1 image' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        image_attributes[existing_article.image_ids.first]['_destroy'] = 'true'
        image_attributes[Time.now.to_i.to_s] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns true' do
        expect(article_form.save).to be_truthy
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'does not change image count' do
        expect { article_form.save }.to change(Image, :count).by(0)
      end

      it 'changes image_ids' do
        destroying_image_ids = existing_article.image_ids
        article_form.save
        expect(existing_article.image_ids).not_to match_array destroying_image_ids
      end
    end

    context 'when an article exists with 1 image and destroying 1 image and adding 10 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        image_attributes[existing_article.image_ids.first]['_destroy'] = 'true'
        10.times { image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns true' do
        expect(article_form.save).to be_truthy
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'changes image count from 1 to 10' do
        expect { article_form.save }.to change(Image, :count).from(1).to(10)
      end
    end

    context 'when an article exists with 1 image and destroying 1 image and adding 11 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 1) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        image_attributes[existing_article.image_ids.first]['_destroy'] = 'true'
        11.times { image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has the error of too_many_images' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:base, :too_many_images)
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'does not increase image count' do
        expect { article_form.save }.to change(Image, :count).by(0)
      end
    end

    context 'when an article exists with 10 images without adding images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns true' do
        expect(article_form.save).to be_truthy
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'does not increase image count' do
        expect { article_form.save }.to change(Image, :count).by(0)
      end
    end

    context 'when an article exists with 10 images and adding 1 image' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        image_attributes[Time.now.to_i.to_s] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has the error of too_many_images' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:base, :too_many_images)
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'does not increase image count' do
        expect { article_form.save }.to change(Image, :count).by(0)
      end
    end

    context 'when an article exists with 10 images and destroying 1 image' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        image_attributes[existing_article.image_ids.sample]['_destroy'] = 'true'
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns true' do
        expect(article_form.save).to be_truthy
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'decreases image count by -1' do
        expect { article_form.save }.to change(Image, :count).by(-1)
      end
    end

    context 'when an article exists with 10 images and destroying 9 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        existing_article.image_ids.sample(9).each { |id| image_attributes[id]['_destroy'] = 'true' }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns true' do
        expect(article_form.save).to be_truthy
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'decreases image count by -9' do
        expect { article_form.save }.to change(Image, :count).by(-9)
      end
    end

    context 'when article exists with 10 images and destroying 9 images and adding 1 image' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        existing_article.image_ids.sample(9).each { |id| image_attributes[id]['_destroy'] = 'true' }
        image_attributes[Time.now.to_i.to_s] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns true' do
        expect(article_form.save).to be_truthy
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'changes image count from 10 to 2' do
        expect { article_form.save }.to change(Image, :count).from(10).to(2)
      end
    end

    context 'when article exists with 10 images and destroying 9 images and adding 9 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        existing_article.image_ids.sample(9).each { |id| image_attributes[id]['_destroy'] = 'true' }
        9.times { image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns true' do
        expect(article_form.save).to be_truthy
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'does not change image count' do
        expect { article_form.save }.to change(Image, :count).by(0)
      end

      it 'changes image_ids' do
        destroying_image_ids = existing_article.image_ids
        article_form.save
        expect(existing_article.image_ids).not_to match_array destroying_image_ids
      end
    end

    context 'when article exists with 10 images and destroying 9 images and adding 10 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        existing_article.image_ids.sample(9).each { |id| image_attributes[id]['_destroy'] = 'true' }
        10.times { image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has the error of too_many_images' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:base, :too_many_images)
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'does not increase image count' do
        expect { article_form.save }.to change(Image, :count).by(0)
      end
    end

    context 'when an article exists with 10 images and destroying 10 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        existing_article.image_ids.each { |id| image_attributes[id]['_destroy'] = 'true' }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has the error of require_images' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:base, :require_images)
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'does not decrease image count' do
        expect { article_form.save }.to change(Image, :count).by(0)
      end
    end

    context 'when an article exists with 10 images and destroying 10 images and adding 1 image' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        existing_article.image_ids.each { |id| image_attributes[id]['_destroy'] = 'true' }
        image_attributes[Time.now.to_i.to_s] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns true' do
        expect(article_form.save).to be_truthy
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'changes image count from 10 to 1' do
        expect { article_form.save }.to change(Image, :count).from(10).to(1)
      end
    end

    context 'when an article exists with 10 images and destroying 10 images and adding 10 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        existing_article.image_ids.each { |id| image_attributes[id]['_destroy'] = 'true' }
        10.times { image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns true' do
        expect(article_form.save).to be_truthy
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'does not change image count' do
        expect { article_form.save }.to change(Image, :count).by(0)
      end

      it 'changes image_ids' do
        destroying_image_ids = existing_article.image_ids
        article_form.save
        expect(existing_article.image_ids).not_to match_array destroying_image_ids
      end
    end

    context 'when an article exists with 10 images and destroying 10 images and adding 11 images' do
      let!(:existing_article) { create(:article, :with_images, images_count: 10) }
      let(:article_form) do
        image_attributes = described_class.new(article: existing_article).image_attributes
        existing_article.image_ids.each { |id| image_attributes[id]['_destroy'] = 'true' }
        11.times { image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has the error of too_many_images' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:base, :too_many_images)
      end

      it 'does not increase article count' do
        expect { article_form.save }.to change(Article, :count).by(0)
      end

      it 'does not increase image count' do
        expect { article_form.save }.to change(Image, :count).by(0)
      end
    end

    context 'when new article and article and images are invalid' do
      let(:article_form) do
        attributes = attributes_for(:article, title: nil)
        described_class.new(attributes, article: Article.new)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has article error and image error' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:title, :blank)
        expect(article_form.errors).to be_of_kind(:base, :require_images)
      end
    end

    context 'when an article exists with images and article and images are invalid' do
      let(:article_form) do
        existing_article = create(:article, :with_images, images_count: 1)
        image_attributes = described_class.new(article: existing_article).image_attributes
        10.times { image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article, body: nil), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has article error and image error' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:body, :blank)
        expect(article_form.errors).to be_of_kind(:base, :too_many_images)
      end
    end
  end
end

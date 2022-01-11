require 'rails_helper'

RSpec.describe ArticleForm, type: :model do
  def example_image_path
    Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
  end

  def random_number
    SecureRandom.random_number(1 << 64)
  end

  def create_image_attributes(existing_article)
    existing_article.images.map do |image|
      [image.id, { **image.attributes.slice('id'), '_destroy' => 'false' }]
    end.to_h
  end

  describe '#new_cl_ids' do
    context 'when new article with no images' do
      it 'returns []' do
        attributes = { **attributes_for(:article), image_attributes: nil }
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.new_cl_ids).to eq []
      end
    end

    context 'when new article with 1 image' do
      it 'returns an array of cl_id' do
        image_path = example_image_path
        image_attributes = { Time.now.to_i.to_s => { 'cl_id' => image_path } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.new_cl_ids).to eq [image_path]
      end
    end

    context 'when new article with 2 image' do
      it 'returns an array of cl_ids' do
        image_attributes = {}
        example_image_paths = []
        2.times do
          image_path = example_image_path
          image_attributes[random_number] = { 'cl_id' => image_path }
          example_image_paths << image_path
        end
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.new_cl_ids).to eq example_image_paths
      end
    end

    context 'when an article exists without adding images' do
      it 'returns []' do
        existing_article = create(:article, :with_an_image)
        image_attributes = create_image_attributes(existing_article)
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: existing_article)
        expect(article_form.new_cl_ids).to eq []
      end
    end

    context 'when an article exists and adding 1 image' do
      it 'returns an array of cl_id' do
        existing_article = create(:article, :with_an_image)
        image_attributes = create_image_attributes(existing_article)
        image_path = example_image_path
        image_attributes[Time.now.to_i.to_s] = { 'cl_id' => image_path }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: existing_article)
        expect(article_form.new_cl_ids).to eq [image_path]
      end
    end

    context 'when article exists and adding 2 images' do
      it 'returns an array of cl_ids' do
        existing_article = create(:article, :with_an_image)
        image_attributes = create_image_attributes(existing_article)
        example_image_paths = []
        10.times do
          image_path = example_image_path
          image_attributes[random_number] = { 'cl_id' => image_path }
          example_image_paths << image_path
        end
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: existing_article)
        expect(article_form.new_cl_ids).to eq example_image_paths
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

    context 'when new article and adding an image' do
      it 'returns []' do
        image_attributes = { Time.now.to_i.to_s => { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.destroying_image_ids).to eq []
      end
    end

    context 'when an article exists without destroying images' do
      it 'returns []' do
        existing_article = create(:article, :with_an_image)
        image_attributes = create_image_attributes(existing_article)
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: existing_article)
        expect(article_form.destroying_image_ids).to eq []
      end
    end

    context 'when an article exists and destroying images' do
      let(:existing_article) { create(:article, :with_3_images) }

      it 'returns an array of destroying_image_id' do
        destroying_image_id = existing_article.image_ids.sample
        image_attributes = create_image_attributes(existing_article)
        image_attributes[destroying_image_id]['_destroy'] = 'true'
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: existing_article)
        expect(article_form.destroying_image_ids).to eq [destroying_image_id]
      end

      it 'returns an array of destroying_image_ids' do
        destroying_image_ids = existing_article.image_ids.sample(2)
        image_attributes = create_image_attributes(existing_article)
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
      let!(:existing_article) { create(:article, :with_an_image) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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
      let!(:existing_article) { create(:article, :with_an_image) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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
      let!(:existing_article) { create(:article, :with_an_image) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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
      let!(:existing_article) { create(:article, :with_an_image) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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

    context 'when an article exists with 9 images without adding images' do
      let!(:existing_article) { create(:article, :with_9_images) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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

    context 'when an article exists with 9 images and adding 1 image' do
      let!(:existing_article) { create(:article, :with_9_images) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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

    context 'when an article exists with 9 images and adding 2 images' do
      let!(:existing_article) { create(:article, :with_9_images) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
        2.times { image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
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
      let!(:existing_article) { create(:article, :with_10_images) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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
      let!(:existing_article) { create(:article, :with_10_images) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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

    context 'when an article exists with 1 image and article and images are invalid' do
      let(:article_form) do
        existing_article = create(:article, :with_an_image)
        image_attributes = create_image_attributes(existing_article)
        10.times { image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article, title: nil), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has article error and image error' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:title, :blank)
        expect(article_form.errors).to be_of_kind(:base, :too_many_images)
      end
    end

    context 'when an article exists with 9 images and article and images are invalid' do
      let(:article_form) do
        existing_article = create(:article, :with_9_images)
        image_attributes = create_image_attributes(existing_article)
        2.times { image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) } }
        attributes = { **attributes_for(:article, title: nil), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has article error and image error' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:title, :blank)
        expect(article_form.errors).to be_of_kind(:base, :too_many_images)
      end
    end

    context 'when an article exists with 10 images and article and images are invalid' do
      let(:article_form) do
        existing_article = create(:article, :with_10_images)
        image_attributes = create_image_attributes(existing_article)
        image_attributes[Time.now.to_i.to_s] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image_path) }
        attributes = { **attributes_for(:article, title: nil), image_attributes: image_attributes }
        described_class.new(attributes, article: existing_article)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has article error and image error' do
        article_form.save
        expect(article_form.errors).to be_of_kind(:title, :blank)
        expect(article_form.errors).to be_of_kind(:base, :too_many_images)
      end
    end

    context 'when an article exists with 1 image and destroying 1 image' do
      let!(:existing_article) { create(:article, :with_an_image) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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

    context 'when an article exists with 2 image and destroying 1 image' do
      let!(:existing_article) { create(:article, :with_2_images) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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

    context 'when an article exists with 10 images and destroying 1 image' do
      let!(:existing_article) { create(:article, :with_10_images) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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
      let!(:existing_article) { create(:article, :with_10_images) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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

    context 'when an article exists with 10 images and destroying 10 images' do
      let!(:existing_article) { create(:article, :with_10_images) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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

    context 'when an article exists with 1 image and destroying 1 image and adding 1 image' do
      let!(:existing_article) { create(:article, :with_an_image) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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
        expect(existing_article.reload.image_ids).not_to match_array destroying_image_ids
      end
    end

    context 'when an article exists with 1 image and destroying 1 image and adding 10 images' do
      let!(:existing_article) { create(:article, :with_an_image) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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
      let!(:existing_article) { create(:article, :with_an_image) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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

    context 'when an article exists with 10 images and destroying 10 images and adding 1 image' do
      let!(:existing_article) { create(:article, :with_10_images) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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
      let!(:existing_article) { create(:article, :with_10_images) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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
        expect(existing_article.reload.image_ids).not_to match_array destroying_image_ids
      end
    end

    context 'when an article exists with 10 images and destroying 10 images and adding 11 images' do
      let!(:existing_article) { create(:article, :with_10_images) }
      let(:article_form) do
        image_attributes = create_image_attributes(existing_article)
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
  end
end

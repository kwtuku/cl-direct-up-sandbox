require 'rails_helper'

RSpec.describe ArticleForm, type: :model do
  describe '#save' do
    context 'without images' do
      it 'returns true' do
        attributes = attributes_for(:article)
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.save).to be_truthy
      end
    end

    context 'with an image' do
      it 'returns true' do
        example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
        cl_ids = { cl_ids: [Rack::Test::UploadedFile.new(example_image)] }
        attributes = attributes_for(:article).merge(cl_ids)
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.save).to be_truthy
      end
    end

    context 'with 10 images' do
      it 'returns true' do
        images = []
        10.times do
          example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
          images << Rack::Test::UploadedFile.new(example_image)
        end
        cl_ids = { cl_ids: images }
        attributes = attributes_for(:article).merge(cl_ids)
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.save).to be_truthy
      end
    end

    context 'with 11 images' do
      it 'returns false' do
        images = []
        11.times do
          example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
          images << Rack::Test::UploadedFile.new(example_image)
        end
        cl_ids = { cl_ids: images }
        attributes = attributes_for(:article).merge(cl_ids)
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.save).to be_falsey
        expect(article_form.errors).to be_of_kind(:base, :too_many_images)
      end
    end
  end
end

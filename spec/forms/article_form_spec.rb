require 'rails_helper'

RSpec.describe ArticleForm, type: :model do
  describe '#save' do
    context 'without images' do
      let(:article_form) do
        attributes = attributes_for(:article)
        described_class.new(attributes, article: Article.new)
      end

      it 'returns true' do
        expect(article_form.save).to be_truthy
      end

      it 'increases article count by 1' do
        expect { article_form.save }.to change(Article, :count).by(1)
      end

      it 'does not increase image count' do
        expect { article_form.save }.to change(Image, :count).by(0)
      end
    end

    context 'with an image' do
      let(:article_form) do
        example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
        cl_ids = { cl_ids: [Rack::Test::UploadedFile.new(example_image)] }
        attributes = attributes_for(:article).merge(cl_ids)
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

    context 'with 10 images' do
      let(:article_form) do
        images = []
        10.times do
          example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
          images << Rack::Test::UploadedFile.new(example_image)
        end
        cl_ids = { cl_ids: images }
        attributes = attributes_for(:article).merge(cl_ids)
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

    context 'with 11 images' do
      let(:article_form) do
        images = []
        11.times do
          example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
          images << Rack::Test::UploadedFile.new(example_image)
        end
        cl_ids = { cl_ids: images }
        attributes = attributes_for(:article).merge(cl_ids)
        described_class.new(attributes, article: Article.new)
      end

      it 'returns false' do
        expect(article_form.save).to be_falsey
      end

      it 'has the error' do
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

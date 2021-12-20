require 'rails_helper'

RSpec.describe ArticleForm, type: :model do
  describe '#save' do
    context 'when new article' do
      context 'when title is blank' do
        let(:article_form) do
          attributes = attributes_for(:article, title: nil)
          described_class.new(attributes, article: Article.new)
        end

        it 'returns false' do
          expect(article_form.save).to be_falsey
        end

        it 'has the error' do
          article_form.save
          expect(article_form.errors).to be_of_kind(:title, :blank)
        end

        it 'does not increase article count' do
          expect { article_form.save }.to change(Article, :count).by(0)
        end
      end

      context 'when body is blank' do
        let(:article_form) do
          attributes = attributes_for(:article, body: nil)
          described_class.new(attributes, article: Article.new)
        end

        it 'returns false' do
          expect(article_form.save).to be_falsey
        end

        it 'has the error' do
          article_form.save
          expect(article_form.errors).to be_of_kind(:body, :blank)
        end

        it 'does not increase article count' do
          expect { article_form.save }.to change(Article, :count).by(0)
        end
      end

      context 'when cl_ids is blank' do
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

      context 'when cl_ids count is 1' do
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

      context 'when cl_ids count is 10' do
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

      context 'when cl_ids count is 11' do
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

    context 'when an article exists and has an image' do
      let!(:existing_article) { create(:article, :with_an_image) }

      context 'when cl_ids is blank' do
        let(:article_form) do
          attributes = attributes_for(:article)
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

      context 'when cl_ids count is 1' do
        let(:article_form) do
          example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
          cl_ids = { cl_ids: [Rack::Test::UploadedFile.new(example_image)] }
          attributes = attributes_for(:article).merge(cl_ids)
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

      context 'when cl_ids count is 9' do
        let(:article_form) do
          images = []
          9.times do
            example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
            images << Rack::Test::UploadedFile.new(example_image)
          end
          cl_ids = { cl_ids: images }
          attributes = attributes_for(:article).merge(cl_ids)
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

      context 'when cl_ids count is 10' do
        let(:article_form) do
          images = []
          10.times do
            example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
            images << Rack::Test::UploadedFile.new(example_image)
          end
          cl_ids = { cl_ids: images }
          attributes = attributes_for(:article).merge(cl_ids)
          described_class.new(attributes, article: existing_article)
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

    context 'when an article exists and has 9 images' do
      let!(:existing_article) { create(:article, :with_9_images) }

      context 'when cl_ids is blank' do
        let(:article_form) do
          attributes = attributes_for(:article)
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

      context 'when cl_ids count is 1' do
        let(:article_form) do
          example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
          cl_ids = { cl_ids: [Rack::Test::UploadedFile.new(example_image)] }
          attributes = attributes_for(:article).merge(cl_ids)
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

      context 'when cl_ids count is 2' do
        let(:article_form) do
          images = []
          2.times do
            example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
            images << Rack::Test::UploadedFile.new(example_image)
          end
          cl_ids = { cl_ids: images }
          attributes = attributes_for(:article).merge(cl_ids)
          described_class.new(attributes, article: existing_article)
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

    context 'when an article exists and has 10 images' do
      let!(:existing_article) { create(:article, :with_10_images) }

      context 'when cl_ids is blank' do
        let(:article_form) do
          attributes = attributes_for(:article)
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

      context 'when cl_ids count is 1' do
        let(:article_form) do
          example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
          cl_ids = { cl_ids: [Rack::Test::UploadedFile.new(example_image)] }
          attributes = attributes_for(:article).merge(cl_ids)
          described_class.new(attributes, article: existing_article)
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

    context 'when article and images are invalid' do
      context 'when new arcitle' do
        let(:article_form) do
          images = []
          11.times do
            example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
            images << Rack::Test::UploadedFile.new(example_image)
          end
          cl_ids = { cl_ids: images }
          attributes = attributes_for(:article, title: nil).merge(cl_ids)
          described_class.new(attributes, article: Article.new)
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

      context 'when an article exists and has an image' do
        let(:article_form) do
          images = []
          10.times do
            example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
            images << Rack::Test::UploadedFile.new(example_image)
          end
          cl_ids = { cl_ids: images }
          attributes = attributes_for(:article, title: nil).merge(cl_ids)
          described_class.new(attributes, article: create(:article, :with_an_image))
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

      context 'when an article exists and has 9 images' do
        let(:article_form) do
          images = []
          2.times do
            example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
            images << Rack::Test::UploadedFile.new(example_image)
          end
          cl_ids = { cl_ids: images }
          attributes = attributes_for(:article, title: nil).merge(cl_ids)
          described_class.new(attributes, article: create(:article, :with_9_images))
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

      context 'when an article exists and has 10 images' do
        let(:article_form) do
          example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
          cl_ids = { cl_ids: [Rack::Test::UploadedFile.new(example_image)] }
          attributes = attributes_for(:article, title: nil).merge(cl_ids)
          described_class.new(attributes, article: create(:article, :with_10_images))
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
    end
  end
end
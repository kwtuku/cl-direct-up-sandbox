require 'rails_helper'

RSpec.describe ArticleForm, type: :model do
  def create_image_attributes(existing_article)
    existing_article.images.map do |image|
      [image.id, image.attributes.slice('id').merge({ '_destroy' => 'false' })]
    end.to_h
  end

  describe '#new_cl_ids' do
    context 'when new article and image_attributes does not have cl_id' do
      it 'returns []' do
        attributes = { **attributes_for(:article), image_attributes: nil }
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.new_cl_ids).to eq []
      end
    end

    context 'when new article and image_attributes has a cl_id' do
      it 'returns an array of cl_id' do
        example_image_path = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
        image_attributes = { Time.now.to_i.to_s => { 'cl_id' => example_image_path } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.new_cl_ids).to eq [example_image_path]
      end
    end

    context 'when new article and image_attributes has 2 cl_id' do
      it 'returns an array of cl_ids' do
        image_attributes = {}
        example_image_paths = []
        2.times do
          example_image_path = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
          random_number = SecureRandom.random_number(1 << 64)
          image_attributes[random_number] = { 'cl_id' => example_image_path }
          example_image_paths << example_image_path
        end
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.new_cl_ids).to eq example_image_paths
      end
    end

    context 'when an article exists and image_attributes does not have cl_id' do
      it 'returns []' do
        existing_article = create(:article, :with_an_image)
        image_attributes = create_image_attributes(existing_article)
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: existing_article)
        expect(article_form.new_cl_ids).to eq []
      end
    end

    context 'when an article exists and image_attributes has a cl_id' do
      it 'returns an array of cl_id' do
        existing_article = create(:article, :with_an_image)
        image_attributes = create_image_attributes(existing_article)
        example_image_path = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
        image_attributes[Time.now.to_i.to_s] = { 'cl_id' => example_image_path }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: existing_article)
        expect(article_form.new_cl_ids).to eq [example_image_path]
      end
    end

    context 'when article exists and image_attributes has 2 cl_id' do
      it 'returns an array of cl_ids' do
        existing_article = create(:article, :with_an_image)
        image_attributes = create_image_attributes(existing_article)
        example_image_paths = []
        2.times do
          example_image_path = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
          random_number = SecureRandom.random_number(1 << 64)
          image_attributes[random_number] = { 'cl_id' => example_image_path }
          example_image_paths << example_image_path
        end
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: existing_article)
        expect(article_form.new_cl_ids).to eq example_image_paths
      end
    end
  end

  describe '#destroying_image_ids' do
    context 'when new article and image_attributes is nil' do
      it 'returns []' do
        attributes = { **attributes_for(:article), image_attributes: nil }
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.destroying_image_ids).to eq []
      end
    end

    context 'when new article and image_attributes has a cl_id' do
      it 'returns []' do
        example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
        image_attributes = { Time.now.to_i.to_s => { 'cl_id' => Rack::Test::UploadedFile.new(example_image) } }
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: Article.new)
        expect(article_form.destroying_image_ids).to eq []
      end
    end

    context 'when an article exists and image_attributes does not have _destroy true' do
      it 'returns []' do
        existing_article = create(:article, :with_an_image)
        image_attributes = create_image_attributes(existing_article)
        attributes = { **attributes_for(:article), image_attributes: image_attributes }
        article_form = described_class.new(attributes, article: existing_article)
        expect(article_form.destroying_image_ids).to eq []
      end
    end

    context 'when an article exists and image_attributes has _destroy true' do
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
    context 'when new article' do
      context 'when title is blank' do
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

      context 'when body is blank' do
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

      context 'when image_attributes cl_id is blank' do
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

      context 'when image_attributes cl_id count is 1' do
        let(:article_form) do
          example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
          image_attributes = { Time.now.to_i.to_s => { 'cl_id' => Rack::Test::UploadedFile.new(example_image) } }
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

      context 'when image_attributes cl_id count is 10' do
        let(:article_form) do
          image_attributes = {}
          10.times do
            example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
            random_number = SecureRandom.random_number(1 << 64)
            image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image) }
          end
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

      context 'when image_attributes cl_id count is 11' do
        let(:article_form) do
          image_attributes = {}
          11.times do
            example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
            random_number = SecureRandom.random_number(1 << 64)
            image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image) }
          end
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
    end

    context 'when an article exists and has an image' do
      let!(:existing_article) { create(:article, :with_an_image) }

      context 'when image_attributes cl_id is blank' do
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

      context 'when image_attributes cl_id count is 1' do
        let(:article_form) do
          image_attributes = create_image_attributes(existing_article)
          example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
          image_attributes[Time.now.to_i.to_s] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image) }
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

      context 'when image_attributes cl_id count is 9' do
        let(:article_form) do
          image_attributes = create_image_attributes(existing_article)
          9.times do
            example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
            random_number = SecureRandom.random_number(1 << 64)
            image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image) }
          end
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

      context 'when image_attributes cl_id count is 10' do
        let(:article_form) do
          image_attributes = create_image_attributes(existing_article)
          10.times do
            example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
            random_number = SecureRandom.random_number(1 << 64)
            image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image) }
          end
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

    context 'when an article exists and has 9 images' do
      let!(:existing_article) { create(:article, :with_9_images) }

      context 'when image_attributes cl_id is blank' do
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

      context 'when image_attributes cl_id cl_id is 1' do
        let(:article_form) do
          image_attributes = create_image_attributes(existing_article)
          example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
          image_attributes[Time.now.to_i.to_s] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image) }
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

      context 'when image_attributes cl_id count is 2' do
        let(:article_form) do
          image_attributes = create_image_attributes(existing_article)
          2.times do
            example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
            random_number = SecureRandom.random_number(1 << 64)
            image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image) }
          end
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

    context 'when an article exists and has 10 images' do
      let!(:existing_article) { create(:article, :with_10_images) }

      context 'when image_attributes cl_id is blank' do
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

      context 'when image_attributes cl_id count is 1' do
        let(:article_form) do
          image_attributes = create_image_attributes(existing_article)
          example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
          image_attributes[Time.now.to_i.to_s] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image) }
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

    context 'when article and images are invalid' do
      context 'when new article' do
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

      context 'when an article exists and has an image' do
        let(:article_form) do
          existing_article = create(:article, :with_an_image)
          image_attributes = create_image_attributes(existing_article)
          10.times do
            example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
            random_number = SecureRandom.random_number(1 << 64)
            image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image) }
          end
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

      context 'when an article exists and has 9 images' do
        let(:article_form) do
          existing_article = create(:article, :with_9_images)
          image_attributes = create_image_attributes(existing_article)
          2.times do
            example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
            random_number = SecureRandom.random_number(1 << 64)
            image_attributes[random_number] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image) }
          end
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

      context 'when an article exists and has 10 images' do
        let(:article_form) do
          existing_article = create(:article, :with_10_images)
          image_attributes = create_image_attributes(existing_article)
          example_image = Rails.root.join("spec/fixtures/files/example.#{%w[jpg jpeg png webp].sample}")
          image_attributes[Time.now.to_i.to_s] = { 'cl_id' => Rack::Test::UploadedFile.new(example_image) }
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
    end
  end
end

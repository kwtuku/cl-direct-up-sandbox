require 'rails_helper'

RSpec.describe 'Articles', type: :system do
  before do
    create(:article, :with_images, images_count: 1)
    create_list(:article, 2, :with_images, images_count: 2)
    create(:article, :with_images, images_count: 3) do |article|
      article.images.first.update(position: 4)
      create(:image, position: 1, article: article)
    end
  end

  it 'has articles ordered by id' do
    visit articles_path
    displayed_articles = all('[data-rspec-article-id]').map { |el| el['data-rspec-article-id'] }
    expect(displayed_articles).to eq Article.ids.map(&:to_s).reverse
  end

  it 'has first images ordered by position' do
    visit articles_path
    displayed_images = all('[data-rspec-image-id]').map { |el| el['data-rspec-image-id'] }
    first_images = Article.all.reverse.map { |article| article.images.find_by(position: 1).id.to_s }
    expect(displayed_images).to eq first_images
  end
end

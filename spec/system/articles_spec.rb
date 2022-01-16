require 'rails_helper'

RSpec.describe 'Articles', type: :system do
  before do
    create(:article, :with_an_image)
    create_list(:article, 2, :with_2_images)
    create(:article, :with_3_images) do |article|
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

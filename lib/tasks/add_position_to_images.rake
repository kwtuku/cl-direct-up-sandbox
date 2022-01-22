namespace :add_position_to_images do
  desc 'Add position to images'
  task run: :environment do
    articles = Article.left_joins(:images).where(images: { position: nil }).uniq
    articles.each do |article|
      article.images.each.with_index(1) do |image, i|
        image.update!(position: i)
      end
    end
  end
end

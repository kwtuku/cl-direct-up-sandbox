class ArticleForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :title, :body

  attribute :image_attributes

  delegate :persisted?, to: :article

  validates :title, presence: true
  validates :body, presence: true
  validate :validate_images_count

  MAX_IMAGES_COUNT = 10
  MIN_IMAGES_COUNT = 1

  def initialize(attributes = nil, article: Article.new)
    @article = article
    attributes ||= default_attributes
    super(attributes)
  end

  def save
    return if invalid?

    ActiveRecord::Base.transaction do
      article.update!(title: title, body: body)

      destroying_images = article.images.where(id: destroying_image_ids)
      destroying_images.delete_all if destroying_images.present?

      updating_images = article.images.where(id: updating_image_ids).reorder(:id)
      updating_images.zip(updating_image_positions) do |image, position|
        image.position = position
        image.save!(context: :article_form_save)
      end

      new_image_attributes_collection.each do |attrs|
        article.images.new(cl_id: attrs['cl_id'], position: attrs['position']).save!(context: :article_form_save)
      end
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.each { |error| errors.add(error.attribute.to_sym, error.type.to_sym, message: error.message) }
    false
  end

  def to_model
    article
  end

  def sanitized_image_attributes_collection
    return [] if image_attributes.nil?

    article_image_ids = article.image_ids
    image_attributes.values
      .reject { |attrs| attrs['id'] && article_image_ids.exclude?(attrs['id'].to_i) }
      .reject { |attrs| attrs['_destroy'] && !attrs['id'] }
      .reject { |attrs| attrs['_destroy'] == 'false' && !attrs['position'] }
  end

  def updating_image_attributes_collection
    sanitized_image_attributes_collection.filter { |attrs| attrs['_destroy'] == 'false' }
  end

  def updating_image_ids
    updating_image_attributes_collection.map { |attrs| attrs['id'] }
  end

  def updating_image_positions
    updating_image_attributes_collection.sort_by { |attrs| attrs['id'].to_i }.map { |attrs| attrs['position'] }
  end

  def new_image_attributes_collection
    sanitized_image_attributes_collection.filter { |attrs| attrs['cl_id'] }
  end

  def destroying_image_ids
    sanitized_image_attributes_collection.filter { |attrs| attrs['_destroy'] == 'true' }.map { |attrs| attrs['id'] }
  end

  private

  attr_reader :article

  def default_attributes
    image_attributes = article.images.map do |image|
      [image.id, { **image.attributes.slice('id', 'position'), '_destroy' => 'false' }]
    end.to_h

    {
      title: article.title,
      body: article.body,
      image_attributes: image_attributes
    }
  end

  def validate_images_count
    images_count = article.images.size - destroying_image_ids.size + new_image_attributes_collection.size

    errors.add(:base, :require_images, message: "記事には画像が#{MIN_IMAGES_COUNT}枚以上必要です") if images_count < MIN_IMAGES_COUNT
    return if images_count <= MAX_IMAGES_COUNT

    errors.add(:base, :too_many_images, message: "記事の画像は#{MAX_IMAGES_COUNT}枚以下にしてください")
  end
end

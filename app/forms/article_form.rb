class ArticleForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :title, :body

  attribute :image_attributes

  delegate :persisted?, to: :article

  validates :title, presence: true
  validates :body, presence: true
  validate :validate_max_image_count
  validate :validate_min_image_count

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
      article.reload

      updating_images = article.images.where(id: updating_image_ids).reorder(:id)
      updating_images.zip(updating_image_positions) { |image, position| image.update!(position: position) }

      new_image_attributes_collection.each do |attrs|
        article.images.create!(cl_id: attrs['cl_id'], position: attrs['position'])
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

  def updating_image_attributes_collection
    return [] if image_attributes.nil?

    image_attributes.values.filter { |attrs| attrs['_destroy'] == 'false' }
  end

  def updating_image_ids
    return [] if image_attributes.nil?

    updating_image_attributes_collection.map { |attrs| attrs['id'] }
  end

  def updating_image_positions
    return [] if image_attributes.nil?

    updating_image_attributes_collection.sort_by { |attrs| attrs['id'].to_i }.map { |attrs| attrs['position'] }
  end

  def new_image_attributes_collection
    return [] if image_attributes.nil?

    image_attributes.values.filter { |attrs| attrs['cl_id'] }
  end

  def destroying_image_ids
    return [] if image_attributes.nil?

    image_attributes.values.filter { |attrs| attrs['_destroy'] == 'true' }.map { |attrs| attrs['id'] }
  end

  def saved_images
    return [] if image_attributes.nil?

    image_attributes.values.filter { |v| v['_destroy'] != 'true' }
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

  IMAGE_MAX_COUNT = 10
  def validate_max_image_count
    return if saved_images.size <= IMAGE_MAX_COUNT

    errors.add(:base, :too_many_images, message: "記事の画像は#{IMAGE_MAX_COUNT}枚以下にしてください")
  end

  IMAGE_MIN_COUNT = 1
  def validate_min_image_count
    return if saved_images.size >= IMAGE_MIN_COUNT

    errors.add(:base, :require_images, message: "記事には画像が#{IMAGE_MIN_COUNT}枚以上必要です")
  end
end

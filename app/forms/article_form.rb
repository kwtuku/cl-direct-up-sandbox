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

      if destroying_image_ids.present?
        destroying_images = article.images.where(id: destroying_image_ids)
        destroying_images.delete_all
        article.reload
      end

      updating_images.each { |image| article.images.find(image['id']).update!(position: image['position']) }
      new_images.each { |image| article.images.create!(cl_id: image['cl_id'], position: image['position']) }
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.each { |error| errors.add(error.attribute.to_sym, error.type.to_sym, message: error.message) }
    false
  end

  def to_model
    article
  end

  def updating_images
    return [] if image_attributes.nil?

    image_attributes.values.filter { |v| v['id'] && v['_destroy'] == 'false' }
  end

  def new_images
    return [] if image_attributes.nil?

    image_attributes.values.filter { |v| v['cl_id'] }
  end

  def new_cl_ids
    return [] if image_attributes.nil?

    image_attributes.values.map { |v| v['cl_id'] }.compact
  end

  def destroying_image_ids
    return [] if image_attributes.nil?

    image_attributes.values.filter { |v| v['_destroy'] == 'true' }.map { |v| v['id'] }
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

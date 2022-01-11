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

      new_cl_ids.each { |cl_id| article.images.create!(cl_id: cl_id) }
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.each { |error| errors.add(error.attribute.to_sym, error.type.to_sym, message: error.message) }
    false
  end

  def to_model
    article
  end

  def new_cl_ids
    return [] if image_attributes.nil?

    image_attributes.map { |_k, v| v['cl_id'] }.compact
  end

  def destroying_image_ids
    return [] if image_attributes.nil?

    image_attributes.select { |_k, v| v['_destroy'] == 'true' }.map { |_k, v| v['id'] }
  end

  private

  attr_reader :article

  def default_attributes
    image_attributes = article.images.map do |image|
      [image.id, image.attributes.slice('id').merge({ '_destroy' => 'false' })]
    end.to_h

    {
      title: article.title,
      body: article.body,
      image_attributes: image_attributes
    }
  end

  IMAGE_MAX_COUNT = 10
  def validate_max_image_count
    return if new_cl_ids.nil?

    return if (article.images.size + new_cl_ids.size - destroying_image_ids.size) <= IMAGE_MAX_COUNT

    errors.add(:base, :too_many_images, message: "記事の画像は#{IMAGE_MAX_COUNT}枚以下にしてください")
  end

  IMAGE_MIN_COUNT = 1
  def validate_min_image_count
    return if new_cl_ids.present?

    return if (article.images.size - destroying_image_ids.size) >= IMAGE_MIN_COUNT

    errors.add(:base, :require_images, message: "記事には画像が#{IMAGE_MIN_COUNT}枚以上必要です")
  end
end

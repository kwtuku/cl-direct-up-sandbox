class ArticleForm
  include ActiveModel::Model

  attr_accessor :title, :body, :cl_ids

  delegate :persisted?, to: :article

  validates :title, presence: true
  validates :body, presence: true
  validate :validate_image_count

  def initialize(attributes = nil, article: Article.new)
    @article = article
    attributes ||= default_attributes
    super(attributes)
  end

  def save
    return if invalid?

    ActiveRecord::Base.transaction do
      article.update!(title: title, body: body)
      cl_ids&.each { |cl_id| article.images.create!(cl_id: cl_id) }
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.each { |error| errors.add(error.attribute.to_sym, error.type.to_sym, message: error.message) }
    false
  end

  def to_model
    article
  end

  private

  attr_reader :article

  def default_attributes
    {
      title: article.title,
      body: article.body,
      cl_ids: article.images.pluck(:cl_id)
    }
  end

  IMAGE_MAX_COUNT = 10
  def validate_image_count
    return unless cl_ids

    return unless article.images.size >= IMAGE_MAX_COUNT

    errors.add(:base, :too_many_images, message: "記事の画像は#{IMAGE_MAX_COUNT}枚以下にしてください")
  end
end

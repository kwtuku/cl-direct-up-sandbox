class Image < ApplicationRecord
  belongs_to :article

  before_destroy :validate_min_images_count

  mount_uploader :cl_id, ImageUploader

  validates :cl_id, presence: { message: 'をアップロードしてください' }
  validate :validate_max_images_count, if: -> { validation_context != :article_form_save }

  MAX_IMAGES_COUNT = 10
  MIN_IMAGES_COUNT = 1

  private

  def validate_max_images_count
    return if article.images.size <= MAX_IMAGES_COUNT

    errors.add(:base, :too_many_images, message: "記事の画像は#{MAX_IMAGES_COUNT}枚以下にしてください")
  end

  def validate_min_images_count
    return if article.images.size > MIN_IMAGES_COUNT

    errors.add(:base, :require_images, message: "記事には画像が#{MIN_IMAGES_COUNT}枚以上必要です")
    throw :abort
  end
end

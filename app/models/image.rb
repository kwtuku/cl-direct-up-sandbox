class Image < ApplicationRecord
  belongs_to :article

  before_destroy :validate_min_image_count

  mount_uploader :cl_id, ImageUploader

  validates :cl_id, presence: { message: 'をアップロードしてください' }
  validate :validate_max_image_count

  private

  IMAGE_MAX_COUNT = 10
  def validate_max_image_count
    return if article.images.size <= IMAGE_MAX_COUNT

    errors.add(:base, :too_many_images, message: "記事の画像は#{IMAGE_MAX_COUNT}枚以下にしてください")
  end

  IMAGE_MIN_COUNT = 1
  def validate_min_image_count
    return if article.images.size > IMAGE_MIN_COUNT

    errors.add(:base, :require_images, message: "記事には画像が#{IMAGE_MIN_COUNT}枚以上必要です")
    throw :abort
  end
end

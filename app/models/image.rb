class Image < ApplicationRecord
  belongs_to :article

  mount_uploader :cl_id, ImageUploader

  validates :cl_id, presence: { message: 'をアップロードしてください' }
  validate :validate_image_count

  private

  IMAGE_MAX_COUNT = 10
  def validate_image_count
    return if article.images.size <= IMAGE_MAX_COUNT

    errors.add(:base, :too_many_images, message: "記事の画像は#{IMAGE_MAX_COUNT}枚以下にしてください")
  end
end

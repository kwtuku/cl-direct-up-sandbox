class Image < ApplicationRecord
  belongs_to :article

  mount_uploader :cl_id, ImageUploader

  validate :validate_image_count

  private

  IMAGE_MAX_COUNT = 10
  def validate_image_count
    return unless article.images.size >= IMAGE_MAX_COUNT

    errors.add(:base, :too_many_images, message: "は#{IMAGE_MAX_COUNT}枚以下にしてください")
  end
end

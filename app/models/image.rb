class Image < ApplicationRecord
  belongs_to :article

  mount_uploader :cl_id, ImageUploader
end

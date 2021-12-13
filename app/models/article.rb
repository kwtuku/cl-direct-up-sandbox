class Article < ApplicationRecord
  has_many :images, dependent: :destroy
end

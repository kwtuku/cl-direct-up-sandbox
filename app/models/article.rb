class Article < ApplicationRecord
  has_many :images, -> { order(position: :ASC) }, dependent: :destroy, inverse_of: 'article'

  validates :title, presence: true
  validates :body, presence: true
end

class Article < ApplicationRecord
  has_many :images, dependent: :destroy

  validates :title, presence: true
  validates :body, presence: true
end

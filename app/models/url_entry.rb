class UrlEntry < ApplicationRecord
  belongs_to :note

  validates :text, :url, presence: true

  def to_s
    text + ' ' + url
  end
end
class TextEntry < ApplicationRecord
  belongs_to :note

  validates :text, presence: true

  def to_s
    text
  end

  def index?
    length = text.length
    return true if length < 1000
    Zlib::Deflate.deflate(text).length.fdiv(length) < 0.3
  end
end
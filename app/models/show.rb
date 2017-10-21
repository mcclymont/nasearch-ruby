class Show < ApplicationRecord
  has_many :notes
  has_one :source
end

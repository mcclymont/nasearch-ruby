class NoteAggregate < ApplicationRecord
  belongs_to :note

  validates :text, presence: true
end
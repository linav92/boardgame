class Game < ApplicationRecord
    has_one_attached :cover
    has_one_attached :rule
    has_many_attached :pieces
end

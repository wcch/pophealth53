class Relationship < ActiveRecord::Base
  extend RandomFinder
  has_select_options
end

class AllergyStatusCode < ActiveRecord::Base
  extend RandomFinder
  has_select_options
end

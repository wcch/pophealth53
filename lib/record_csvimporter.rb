require 'fileutils'
class RecordImporter
  
  def initialize(source_dir, providers_predefined)
    @source_dir = source_dir
    @providers_predefined = providers_predefined
  end
 
  def self.import(data, provider_map = {})

  
record=Record.new
record.first='h'
record.save
    
  end

end

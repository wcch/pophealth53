require 'fileutils'
class RecordImporter
  
  def initialize(source_dir, providers_predefined)
    @source_dir = source_dir
    @providers_predefined = providers_predefined
  end
 
  def self.import(xml_data, provider_map = {})

    

    record = Record.update_or_create(patient_data)
    record.provider_performances = providers
    record.save
    
    {status: 'success', message: 'patient imported', status_code: 201, record: record}
    
  end

end

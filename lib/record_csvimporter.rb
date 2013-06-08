require 'fileutils'
class RecordCsvImporter
  
  def initialize(source_dir, providers_predefined)
    @source_dir = source_dir
    @providers_predefined = providers_predefined
  end
 
  def self.import(data, provider_map = {})

    columnmapping=['title','first', 'last', 'gender', 'birthdate', 'deathdate','effective_time', 'medical_record_number', 'expired', 'languages', 'code','code_set','code', 'code_set', 'code', 'code_set', 'code', 'code_set', 'description', 'specifics', 'time', 'start_time', 'end_time', 'status_code', 'free_text', 'mood_code', 'negationInd', 'oid', 'negationReason', 'reason', 'codes', 'admittype', 'description', 'referenceRange', 'interpretation', 'codes', 'scalar', 'units']

    record=Record.new
    religious_affiliation={}
    race={}
    ethnicity={}
    marital_status={}
    encounters={}
    results={}
    data.each do |row|
    columnmapping.each_with_index do |k, i|
    next if row[i].nil?
    case i
      when 0..3
	#arecord[k]=row[i]
	record.k=row[i]
      when 4..6
	#arecord[k]=HL7Helper.timestamp_to_integer(row[i])
	record.k=HL7Helper.timestamp_to_integer(row[i])
      when 7..9
	arecord[k]=row[i]
      when 10..11
	religious_affiliation[k]=row[i]
      when 12..13
	race[k]=row[i]
      when 14..15
	ethnicity[k]=row[i]
      when 16..17
	marital_status[k]=row[i]
      when 18..19
	encounters[k]=row[i]
      when 20..22
	arecord[k]=HL7Helper.timestamp_to_integer(row[i])
      when 23..29
	encounters[k]=row[i]
      when 30
	codes={}
	codesystem=row[i].split(":")
	codes[codesystem[0]] ||=[]
	codesystem[1].split.each do |code|
	  codes['CPT'] << code
	end
	encounters[k]=codes
      when 32..34
	results[k]=row[i]
      when 35
	codes={}
	codesystem=row[i].split(":")
	codes[codesystem[0]] ||=codesystem[1]
	results[k]=codes
      when 36..37
	results[k]=row[i]
	
      end #end of case
    end  #end of each_with_index
    arecord[:religious_affiliation]=religious_affiliation unless religious_affiliation.empty?
    arecord[:race]=race unless race.empty?
    arecord[:ethnicity]=ethnicity unless ethnicity.empty?
    arecord[:marital_status]=marital_status unless marital_status.empty?
    record=Record.new arecord
    record.encounters << Encounter.new(encounters)
    record.results << ResultValue.new(results)
    end #end of each row
    
    record = Record.update_or_create(record)
    record.provider_performances = providers
    record.save
    
    {status: 'success', message: 'patient imported', status_code: 201, record: record}
    
  end

end
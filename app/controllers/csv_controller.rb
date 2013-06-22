class CsvController < ApplicationController

  include HealthDataStandards::Util
   
  before_filter :authenticate_user!
  before_filter :validate_authorization!

  def csv_upload
	  file = params[:file]
	  
	  #columnmapping=['title','first', 'last', 'gender']
	  temp_file = Tempfile.new("patient_upload")

	    File.open(temp_file.path, "wb") { |f| f.write(file.read) }
	    
	    Zip::ZipFile.open(temp_file.path) do |zipfile|
	      zipfile.each do |file|
		csv = zipfile.read(file)
		
		
		apatient=[]
		CSV.parse(csv) do |row|

		  apatient ||= []
		  if apatient.empty? || apatient.first[7]==row[7]
		    apatient << row
		  else 
		    parse(apatient)
		    apatient=[]
		    apatient << row
		  end


		end #end of csv parse row
		parse(apatient)
	    end #end of zip file each
	end #end of zip file open each
        redirect_to controller: 'admin', action: 'patients'
  end #end of method definition

  def validate_authorization!
    authorize! :admin, :users
  end

  def parse(data)
    

    record=Record.new
    get_demographics(record, data)
    get_encounters(record, data)
    #get_results(record, data)
    record=Record.update_or_create(record)
    #record.save
   
  end

  def get_demographics(record, data)
    row=data.first

    columnmapping=['title','first', 'last', 'gender', 'birthdate', 'deathdate','effective_time', 'medical_record_number', 'expired', 'languages', 'code','code_set','code', 'code_set', 'code', 'code_set', 'code', 'code_set', 'description', 'specifics', 'time', 'start_time', 'end_time', 'status_code', 'free_text', 'mood_code', 'negationInd', 'oid', 'negationReason', 'reason', 'codes', 'admittype', 'description', 'referenceRange', 'interpretation', 'codes', 'scalar', 'units']
    columns=[:title, :first, :last, :gender, :birthdate, :deathdate, :effective_time, 
:medical_record_number, :exired, :languages, :code, :code_set, :code, :code_set, 
:code, :code_set, :code, :code_set]
    religious_affiliation={}
    race={}
    ethnicity={}
    marital_status={}
    columns.each_with_index do |k, i|
    next if row[i].nil?
    case i
    when 0..3, 7..9
      record.update_attribute(k, row[i])
    when 4..6
      record.update_attribute(k, HL7Helper.timestamp_to_integer(row[i]))
    when 10..11
      religious_affiliation[k]=row[i]
    when 12..13
      race[k]=row[i]
    when 14..15
      ethnicity[k]=row[i]
    when 16..17
      marital_status[k]=row[i]
    end
    
    end 
    record.religious_affiliation=religious_affiliation unless religious_affiliation.empty?
    record.race=race unless race.empty?
    record.ethnicity=ethnicity unless ethnicity.empty?
    record.marital_status=marital_status unless marital_status.empty?

  end

  def get_encounters(record, data)
    encounters={}
    results={}
    columns=[:title, :first, :last, :gender, :birthdate, :deathdate,
 :effective_time, :medical_record_number, :exired, :languages, :code,
 :code_set, :code, :code_set, :code, :code_set, :code, :code_set,
 :description, :specifics, :time, :start_time, :end_time, :status_code,
 :free_text, :mood_code, :negationInd, :oid, :negationReason, 
:reason, :codes, :admittype, :description, :specifics, :time, :start_time,
 :end_time, :status_code, :free_text, :mood_code, :negationInd, :oid,
 :negationReason, :reason, :referenceRange, :interpretation,
 :codes, :scalar, :units]
    data.each do |row|
    columns.each_with_index do |k, i|
      next if row[i].nil?
      case i
      when 18..19, 27..29, 31
        encounters[k]=row[i]
      when 20..22
        encounters[k]=HL7Helper.timestamp_to_integer(row[i])
      when 30
      codes={}
      codesystem=row[30].split(":")
	codes[codesystem[0]] ||=[]
	codes[codesystem[0]] << codesystem[1].strip
      encounters[:codes]=codes
	#parse results
      when 32..33, 38..45
        results[k]=row[i]
      when 34..36
        results[k]=HL7Helper.timestamp_to_integer(row[i])
      when 46
      codes={}
      codesystem=row[46].split(":")
	codes[codesystem[0]] ||=[]
	codes[codesystem[0]] << codesystem[1].strip
      results[:codes]=codes
      end
    end
      record.encounters << Encounter.new(encounters) unless encounters.empty?
       
      result = LabResult.new(results) unless results.empty?
      result.set_value(row[47],row[48]) unless row[47].nil? && row[48].nil?
      record.results << result
    end
    
  end

  def get_results(record, data)
    results={}
    data.each do |row|
      results[:description]=row[32] 

      codes={}
      codesystem=row[35].split(":")
	codes[codesystem[0]] ||=[]
	codes[codesystem[0]] << codesystem[1]
      results[:codes]=codes
      result = LabResult.new(results)
      result.set_value(row[36],row[37])
      record.results << result
      #record.results << LabResult.new(results)

    end
    
  end

  def log_measure(record)
    QME::QualityReport.update_patient_results(record.medical_record_number)
    Atna.log(current_user.username, :phi_import)
    Log.create(:username => current_user.username, :event => 'patient record imported', :medical_record_number => record.medical_record_number)
  end

end

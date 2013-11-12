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
		CSV.parse(csv, col_sep: '|') do |row|

		  apatient ||= []
		  if apatient.empty? || apatient.first[1]==row[1]
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
    record=Record.update_or_create(record)
    get_sections(record, data)
    
    #patient.update_attributes(encounters: nil)
    #patient.encounters << record.encounters
    #patient.update_attributes(results: nil)
    #patient.results << record.results
    #patient.save
    record.save
   
  end

  def get_demographics(record, data)
    row=data.first
    return '' if row[0] !='Demographics'
    columns=[:sectionType, :medical_record_number, :title, :first, :last, :gender, :birthdate, 
:deathdate, :effective_time,  :exired, :languages, :code, :code_set, :code, :code_set, 
:code, :code_set, :code, :code_set]
    religious_affiliation={}
    race={}
    ethnicity={}
    marital_status={}
    columns.each_with_index do |k, i|
    next if row[i].nil?
    case i
    when 1..5, 9..10
      record.assign_attributes(k=>row[i])
    when 6..8
      record.assign_attributes(k => HL7Helper.timestamp_to_integer(row[i]))
    when 11..12
      religious_affiliation[k]=row[i]
    when 13..14
      race[k]=row[i]
    when 15..16
      ethnicity[k]=row[i]
    when 17..18
      marital_status[k]=row[i]
    end
    
    end 
    record.religious_affiliation=religious_affiliation unless religious_affiliation.empty?
    record.race=race unless race.empty?
    record.ethnicity=ethnicity unless ethnicity.empty?
    record.marital_status=marital_status unless marital_status.empty?

  end

  def get_sections(record,data)
    data.shift
    encounterRows=[]
    resultRows=[]
    conditionRows=[]
    procedureRows=[]
    vitalSigns=[]
    medicationRows=[]
    data.each do |row|
      # Group sections
      next if row[0].nil?
      case row[0]
      when "Encounters"
	encounterRows << row
      when "Results"
	resultRows << row
      when "Conditions"
	conditionRows << row
      when "Procedures"
	procedureRows << row
      when "VitalSigns"
	vitalSigns << row
      when "Medications"
	medicationRows << row
      end
      
    end
    # update sections in the record
    get_encounters(record, encounterRows)
    get_results(record, resultRows)
    get_condition(record, conditionRows)
    get_procedure(record, procedureRows)
    get_vitalsigns(record, vitalSigns)
    get_medications(record, medicationRows)
  end

  def get_encounters(record, data)
    encounters={}
    data.each do |row|
      entry=get_entry(row)
      encounters=entry
      #parse other fields not in entry
      record.encounters << Encounter.new(encounters) unless encounters.empty?
    end
  end

  def get_results(record, data)
    results={}
    data.each do |row|
    entry=get_entry(row)
      results=entry
      #parse other fields not in entry
      results[:referenceRange]=row[17] unless row[17].nil?
      result = LabResult.new(results) unless results.empty?
      #result.set_value(row[17],row[18]) unless row[17].nil? && row[18].nil?
      get_values(row[15]).each {|pair| result.set_value(pair[0],pair[1])}
      record.results << result
    end
  end

  def get_vitalsigns(record, data)
    vitalsigns={}
    data.each do |row|
    entry=get_entry(row)
      vitalsigns=entry
      #parse other fields not in entry
      vitalsigns[:referenceRange]=row[17] unless row[17].nil?
      vitalsign = LabResult.new(vitalsigns) unless vitalsigns.empty?
      get_values(row[15]).each {|pair| vitalsign.set_value(pair[0],pair[1])}
      record.vital_signs << vitalsign
    end
  end

  def get_condition(record, data)
    conditions={}
    value={}
    data.each do |row|
      entry=get_entry(row)
      conditions=entry
      #parse other fields not in entry
      conditions[:type]=row[17]
      conditions[:causeOfDeath]=row[18]=='false' ? false:true
      value={scalar: row[15], units: row[16]}
      con = Condition.new(conditions) unless conditions.empty?
      con.values << PhysicalQuantityResultValue.new(value)
      record.conditions << con
    end
  end

  def get_procedure(record, data)
    procedures={}
    data.each do |row|
      entry=get_entry(row)
      procedures=entry
      #parse other fields not in entry
      procedures[:site]=row[17]
      record.procedures << Procedure.new(procedures) unless procedures.empty?
    end
  end

  def get_medications(record, data)
    medications={}
    data.each do |row|
      entry=get_entry(row)
      medications=entry
      #parse other fields not in entry
      medications[:administrationTiming]=row[17] unless row[17].nil?
      medications[:freeTextSig]=row[18] unless row[18].nil?
      medications[:dose]=row[19] unless row[19].nil?
      medications[:typeOfMedication]=row[20]  unless row[20].nil?
      medications[:statusOfMedication]=row[21]  unless row[21].nil?
      medications[:route]=row[22] unless row[22].nil?
      medications[:site]=row[23]  unless row[23].nil?
      medications[:doseRestriction]=row[24]  unless row[24].nil?
      medications[:fulfillmentInstructions]=row[25]  unless row[25].nil?
      medications[:indication]=row[26]  unless row[26].nil?
      medications[:productForm]=row[27] unless row[27].nil?
      medications[:vehicle]=row[28] unless row[28].nil?
      medications[:reaction]=row[29] unless row[29].nil?
      medications[:deliveryMethod]=row[30] unless row[30].nil?
      medications[:patientInstructions]=row[31] unless row[31].nil?
      medications[:doseIndicator]=row[32] unless row[32].nil?
      medications[:cumulativeMedicationDuration]=row[33] unless row[33].nil?

      record.medications << Medication.new(medications) unless medications.empty?
    end
  end

  def get_entry(row)
    aentry={}
    columns=[:sectionType, :medical_record_number, :codes, 
 :description, :specifics, :time, :start_time, :end_time, :status_code,
 :free_text, :mood_code, :negationInd, :negationReason, :oid, 
:reason]
    columns.each_with_index do |k, i|
      next if row[i].nil?
      case i
      when 2
      codes={}
      #codesystem=row[2].split(":")
	#codes[codesystem[0]] ||=[]
	#codes[codesystem[0]] << codesystem[1].strip
      codesystem=row[2].split(",")
      codesystem.each do |c|
	codesystem=c.split(":")
	codes[codesystem[0].strip] ||=[]
	codes[codesystem[0].strip] << codesystem[1].strip unless codesystem[1].nil?
      end
      aentry[:codes]=codes
      when 3..4, 9..11, 13
        aentry[k]=row[i]
      when 5..7
        aentry[k]=HL7Helper.timestamp_to_integer(row[i])
      when 8
      codes={}
      
      codesystem=row[8].split(":")
      if codesystem.count>1
      codes[codesystem[0].strip] ||=[]
      codes[codesystem[0].strip] << codesystem[1].strip
      end
      aentry[:status_code]=codes
      end
    end   
    aentry
  end

  def get_values(data)
    return [] if data.nil?
    values=[]
    val=data.split(';')
    val.each do |v|
    value=[]
    v.split('=>').each {|vt| value << vt.strip}
    values << value
    end
    values
  end
 
  def log_measure(record)
    QME::QualityReport.update_patient_results(record.medical_record_number)
    Atna.log(current_user.username, :phi_import)
    Log.create(:username => current_user.username, :event => 'patient record imported', :medical_record_number => record.medical_record_number)
  end

end

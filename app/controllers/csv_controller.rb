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
		  apatient << row if apatient.empty?
		  if apatient.any? && apatient.first[7]==row[7]
		    apatient << row
		  else
		    csvimport(apatient)
		    apatient = []
		    apatient << row
		  end
		  csvimport(apatient)
		end #end of csv parse row
	    end #end of zip file each
	end #end of zip file open each
        redirect_to controller: 'admin', action: 'patients'
  end #end of method definition

  def csvimport(data)
	columnmapping=['title','first', 'last', 'gender', 'birthdate', 'deathdate','effective_time', 'medical_record_number', 'expired', 'languages', 'code','code_set','code', 'code_set', 'code', 'code_set', 'code', 'code_set', 'description', 'specifics', 'time', 'start_time', 'end_time', 'status_code', 'free_text', 'mood_code', 'negationInd', 'oid', 'negationReason', 'reason', 'codes', 'admittype', 'description', 'referenceRange', 'interpretation', 'codes', 'scalar', 'units']
  #mrn ||= row[7]
		  #row=data
		data.each do |row|
		  religious_affiliation={}
		  race={}
		  ethnicity={}
		  marital_status={}
		  encounters={}
		  results={}
		  arecord={}
		  columnmapping.each_with_index do |k, i|
		    next if row[i].nil?
		    case i
		      when 0..3
			arecord[k]=row[i]
		      when 4..6
			arecord[k]=HL7Helper.timestamp_to_integer(row[i])
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
			codes[codesystem[0]] ||=codesystem[1]
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

		  end #end of each with index
		  arecord[:religious_affiliation]=religious_affiliation unless religious_affiliation.empty?
		  arecord[:race]=race unless race.empty?
		  arecord[:ethnicity]=ethnicity unless ethnicity.empty?
		  arecord[:marital_status]=marital_status unless marital_status.empty?
# if record is exist, then update
		  existing=Record.where(medical_record_number: row[7]).first
		  if existing
		    existing.encounters << Encounter.new(encounters)
		    existing.results << ResultValue.new(results)
		  else
		    record=Record.new arecord
		    record.encounters << Encounter.new(encounters)
		    record.results << ResultValue.new(results)
		    record.save!
		  end
		@record=Record.where(medical_record_number: row[7]).first
                 QME::QualityReport.update_patient_results(@record.medical_record_number)
          Atna.log(current_user.username, :phi_import)
          Log.create(:username => current_user.username, :event => 'patient record imported', :medical_record_number => @record.medical_record_number)
    end #end of row each
  end

  def validate_authorization!
    authorize! :admin, :users
  end
end

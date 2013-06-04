class CsvController < ApplicationController
   
  before_filter :authenticate_user!
  before_filter :validate_authorization!

  def csv_upload
	  file = params[:file]
	  columnmapping=['title','first', 'last', 'gender', 'birthdate', 'deathdate', 'religious_affiliation','effective_time', 'name', 'order', 'codes', 'name', 'order', 'codes', 'languages', 'test_id', 'marital_status', 'medical_record_number', 'expired', 'clinicalTrialParticipant', 'description', 'specifics', 'oid', 'reason', 'admitTime', 'dischargeTime']
	  #columnmapping=['title','first', 'last', 'gender']
	  temp_file = Tempfile.new("patient_upload")

	    File.open(temp_file.path, "wb") { |f| f.write(file.read) }
	    
	    Zip::ZipFile.open(temp_file.path) do |zipfile|
	      zipfile.each do |file|
		csv = zipfile.read(file)

		arecord={}
		CSV.parse(csv) do |row|
		  race={}
		  ethnicity={}
		  encounters={}
		  columnmapping.each_with_index do |k, i|
		    case i
		      when 1..8
			arecord[k]=row[i]
		      when 9..11
			race[k]=row[i]
		      when 12..14
			ethnicity[k]=row[i]
		      when 15..20
			arecord[k]=row[i]
		      when 21..26
			encounters[k]=row[i]
		    end
		    #race[k]=row[i] if i>=9 && i<=11
		    #ethnicity[k]=row[i] if i>=12 && i<=14
		    #encounters[k]=row[i] if i>=21 && i<=26
		    #arecord[k]=row[i] if i<9
		  end
		  arecord[:race]=race
		  arecord[:ethnicity]=ethnicity
		  #arecord.encounters << Encounter.new(encounters)
		  record=Record.create! arecord
		  record.encounters << Encounter.new(encounters)

		  #Record.create! row.to_hash
		end
	    end
	end
        redirect_to controller: 'admin', action: 'patients'
  end

  def validate_authorization!
    authorize! :admin, :users
  end
end

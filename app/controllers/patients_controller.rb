class PatientsController < ApplicationController
  include MeasuresHelper

  before_filter :authenticate_user!
  before_filter :validate_authorization!
  before_filter :load_patient, :only => :show
  after_filter :hash_document, :only => :list
  
  add_breadcrumb_dynamic([:patient], only: %w{show}) {|data| patient = data[:patient]; {title: "#{patient.last}, #{patient.first}", url: "/patients/show/#{patient.id}"}}
  
  def index

  end
  
  def list
    measure_id = params[:id] 
    sub_id = params[:sub_id]
    @records = mongo['patient_cache'].find({'value.measure_id' => measure_id, 'value.sub_id' => sub_id,
                                            'value.effective_date' => @effective_date}).to_a
    # log the patient_id of each of the patients that this user has viewed
    @records.each do |patient_container|
      Log.create(:username =>   current_user.username,
                 :event =>      'patient record viewed',
                 :patient_id => (patient_container['value'])['medical_record_id'])
    end
    respond_to do |format|
      format.xml do
        headers['Content-Disposition'] = 'attachment; filename="excel-export.xls"'
        headers['Cache-Control'] = ''
        render :content_type => "application/vnd.ms-excel"
      end
      
      format.html {}
    end
  end

  def show
    @outliers = PatientCache.outliers(@patient).all.map do |patient_cache|
      Measure.get(patient_cache['value']['measure_id'], patient_cache['value']['sub_id']).first
    end
    @manual_exclusions = []
  end
  
  private
  
  def load_patient
    @patient = Record.find(params[:id])
  end
  
  def validate_authorization!
    authorize! :read, Record
  end

end
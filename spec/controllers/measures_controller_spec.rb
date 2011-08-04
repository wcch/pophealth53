require 'spec_helper'

describe MeasuresController do
  include LoginHelper
  
  before do
    collection_fixtures 'measures', 'selected_measures', 'records'
    login
  end
  
  describe "GET 'definition'" do
    it "should be successful" do
      get :definition, :id => '0013'
      response.should be_success
      assigns(:definition).should_not be_nil
    end
  end
  
  describe "GET 'index'" do
    it "should be successful" do
      get :index
      response.should be_success
      assigns(:patient_count).should == 2
      assigns(:grouped_selected_measures).should have_key("Women's Health")
    end
  end
  
  describe "GET 'measure_report'" do
    it "should be successful" do
      @mock_user.stub(:registry_name) {'registry'}
      @mock_user.stub(:registry_id) {'1234'}
      @mock_user.stub(:npi) {'456'}
      @mock_user.stub(:tin) {'789'}
      controller.stub(:extract_result) do |id, sub_id, effective_date|
        { :id => id, :sub_id => sub_id, :population => 5,
          :denominator => 4, :numerator => 2,
          :exclusions => 0
        }
      end
      get :measure_report, :format => :xml
      response.should be_success
      d = Digest::SHA1.new
      checksum = d.hexdigest(response.body)
      l = Log.first(:conditions => {:checksum => checksum})
      l.username.should == 'andy'
    end
  end
  
end
  
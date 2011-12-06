MONGO_DB = Mongoid.database

js_collection = MONGO_DB['system.js']

unless js_collection.find_one('_id' => 'contains')
  js_collection.save('_id' => 'contains', 
                     'value' => BSON::Code.new("function( obj, target ) { return obj.indexOf(target) != -1; };"))
end

# create a unique index for patient cache, this prevents a race condition where the same patient can be entered multiple times for a patient
MONGO_DB.collection('patient_cache').ensure_index([['value.measure_id', Mongo::ASCENDING], ['value.sub_id', Mongo::ASCENDING], ['value.effective_date', Mongo::ASCENDING], ['value.patient_id', Mongo::ASCENDING]], {'unique'=> true})


module QME
  module DatabaseAccess
    # Monkey patch in the connection for the application
    def get_db
      MONGO_DB
    end
  end
end


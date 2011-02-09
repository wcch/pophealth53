Rails.configuration.middleware.use RailsWarden::Manager do |manager|
  manager.default_strategies :my_strategy
  manager.failure_app = AccountController
end

# Setup Session Serialization
class Warden::SessionSerializer

  def serialize(record)
    [record._id]
  end

  def deserialize(keys)
    id = keys[0]
    User.find_one({'_id' => id})
  end

end

# Declare your strategies here
Warden::Strategies.add(:my_strategy) do

  def valid?
    params["username"] || params["password"]
  end

  def authenticate!
    user = User.authenticate(params[:username],params[:password])
    if user
      success!(user)
    else
      errors.add(:login, "Username or Password incorrect")
      fail!
    end
  end

end
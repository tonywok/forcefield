class ImperialClient < Struct.new(:consumer_key, :consumer_secret)

  DUMMY_KEY    = 'key'
  DUMMY_SECRET = 'shhhh'


  def self.find_by_consumer_key(key)
    if key == DUMMY_KEY
      new(key, DUMMY_SECRET)
    end
  end

end


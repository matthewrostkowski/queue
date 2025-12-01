# app/services/venue_code_generator.rb
class VenueCodeGenerator
  # Generate a unique 6-digit code for a venue
  def self.generate_unique_code
    loop do
      code = "%06d" % SecureRandom.random_number(1_000_000)
      break code unless code_taken?(code)
    end
  end

  # Alias for backwards compatibility if needed
  def self.generate
    generate_unique_code
  end

  # Validate that the code is in the correct format (6 digits)
  def self.valid_format?(code)
    code.to_s.match?(/^\d{6}$/)
  end

  # Find a venue by its venue code
  def self.find_by_code(code)
    return nil unless valid_format?(code)
    
    Venue.find_by(venue_code: code)
  end

  class << self
    private

    def code_taken?(code)
      Venue.exists?(venue_code: code)
    end
  end
end

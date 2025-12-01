require 'rails_helper'

RSpec.describe VenueCodeGenerator do
  describe '.generate_unique_code' do
    it 'generates a 6-digit code' do
      code = VenueCodeGenerator.generate_unique_code
      expect(code).to match(/^\d{6}$/)
    end

    it 'generates unique codes' do
      codes = []
      100.times do
        codes << VenueCodeGenerator.generate_unique_code
      end
      # While theoretically duplicates are possible, with 1M possibilities
      # the probability of duplicates in 100 tries is negligible
      expect(codes.uniq.length).to eq(100)
    end

    it 'generates different codes when called multiple times' do
      code1 = VenueCodeGenerator.generate_unique_code
      code2 = VenueCodeGenerator.generate_unique_code
      expect(code1).not_to eq(code2)
    end

    it 'does not generate already taken codes' do
      # Create venue with specific code
      host = User.create!(
        display_name: 'Host',
        auth_provider: 'general_user',
        email: 'host@test.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      Venue.create!(
        name: 'Test Venue',
        host_user_id: host.id,
        venue_code: '123456'
      )

      # Mock SecureRandom to return the taken code first, then a new one
      allow(SecureRandom).to receive(:random_number).and_return(123456, 654321)
      
      code = VenueCodeGenerator.generate_unique_code
      expect(code).to eq('654321')
    end
  end

  describe '.generate' do
    it 'is an alias for generate_unique_code' do
      # Both methods should return 6-digit codes
      code = VenueCodeGenerator.generate
      expect(code).to match(/^\d{6}$/)
    end
  end

  describe '.valid_format?' do
    it 'returns true for valid 6-digit codes' do
      expect(VenueCodeGenerator.valid_format?('123456')).to be true
      expect(VenueCodeGenerator.valid_format?('000001')).to be true
      expect(VenueCodeGenerator.valid_format?('999999')).to be true
    end

    it 'returns false for codes with wrong length' do
      expect(VenueCodeGenerator.valid_format?('12345')).to be false   # too short
      expect(VenueCodeGenerator.valid_format?('1234567')).to be false # too long
      expect(VenueCodeGenerator.valid_format?('1')).to be false       # way too short
      expect(VenueCodeGenerator.valid_format?('')).to be false        # empty
    end

    it 'returns false for non-numeric codes' do
      expect(VenueCodeGenerator.valid_format?('ABC123')).to be false
      expect(VenueCodeGenerator.valid_format?('12345X')).to be false
      expect(VenueCodeGenerator.valid_format?('------')).to be false
      expect(VenueCodeGenerator.valid_format?('12 345')).to be false
    end

    it 'returns false for nil' do
      expect(VenueCodeGenerator.valid_format?(nil)).to be false
    end

    it 'handles numeric input' do
      expect(VenueCodeGenerator.valid_format?(123456)).to be true
      expect(VenueCodeGenerator.valid_format?(12345)).to be false
    end
  end

  describe '.find_by_code' do
    let(:host) do
      User.create!(
        display_name: 'Host',
        auth_provider: 'general_user',
        email: 'host@test.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
    end

    let!(:venue) do
      Venue.create!(
        name: 'Test Venue',
        host_user_id: host.id,
        venue_code: '123456'
      )
    end

    it 'finds venue by code' do
      found_venue = VenueCodeGenerator.find_by_code('123456')
      expect(found_venue).to eq(venue)
    end

    it 'returns nil for non-existent code' do
      found_venue = VenueCodeGenerator.find_by_code('999999')
      expect(found_venue).to be_nil
    end

    it 'returns nil for invalid format' do
      found_venue = VenueCodeGenerator.find_by_code('ABC123')
      expect(found_venue).to be_nil
    end

    it 'returns nil for nil input' do
      found_venue = VenueCodeGenerator.find_by_code(nil)
      expect(found_venue).to be_nil
    end

    it 'returns nil for empty string' do
      found_venue = VenueCodeGenerator.find_by_code('')
      expect(found_venue).to be_nil
    end

    it 'handles numeric input' do
      found_venue = VenueCodeGenerator.find_by_code(123456)
      expect(found_venue).to eq(venue)
    end
  end

  describe 'private methods' do
    describe '.code_taken?' do
      let(:host) do
        User.create!(
          display_name: 'Host',
          auth_provider: 'general_user',
          email: 'host@test.com',
          password: 'password123',
          password_confirmation: 'password123'
        )
      end

      before do
        Venue.create!(
          name: 'Existing Venue',
          host_user_id: host.id,
          venue_code: '111111'
        )
      end

      it 'returns true for taken codes' do
        expect(VenueCodeGenerator.send(:code_taken?, '111111')).to be true
      end

      it 'returns false for available codes' do
        expect(VenueCodeGenerator.send(:code_taken?, '222222')).to be false
      end
    end
  end
end

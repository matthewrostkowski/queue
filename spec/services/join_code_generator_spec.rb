require 'rails_helper'

RSpec.describe JoinCodeGenerator do
  describe ".generate" do
    it "generates a 6-digit code" do
      code = JoinCodeGenerator.generate
      expect(code).to match(/^\d{6}$/)
      expect(code.length).to eq(6)
    end

    it "generates unique codes" do
      codes = 100.times.map { JoinCodeGenerator.generate }
      # While theoretically duplicates are possible, they should be extremely rare
      expect(codes.uniq.length).to be >= 95
    end

    it "generates codes with leading zeros when needed" do
      # Test by mocking SecureRandom to return a small number
      allow(SecureRandom).to receive(:random_number).and_return(42)
      code = JoinCodeGenerator.generate
      expect(code).to eq("000042")
    end

    it "does not generate duplicate codes for existing sessions" do
      # Create an existing session with a specific code
      host_user = User.create!(display_name: "Host", email: "host@example.com", password: "password", auth_provider: "general_user", role: :host)
      venue = Venue.create!(name: "Test Venue", host_user_id: host_user.id)
      existing_session = QueueSession.create!(
        venue: venue,
        status: "active",
        join_code: "123456"
      )

      # Mock SecureRandom to first try to generate the existing code, then a new one
      call_count = 0
      allow(SecureRandom).to receive(:random_number) do
        call_count += 1
        call_count == 1 ? 123456 : 654321
      end

      code = JoinCodeGenerator.generate
      expect(code).to eq("654321")
      expect(code).not_to eq(existing_session.join_code)
    end

    it "checks both join_code and access_code columns if they exist" do
      host_user = User.create!(display_name: "Host", email: "host@example.com", password: "password", auth_provider: "general_user", role: :host)
      venue = Venue.create!(name: "Test Venue", host_user_id: host_user.id)
      
      # Test with join_code
      session1 = QueueSession.create!(
        venue: venue,
        status: "active",
        join_code: "111111"
      )

      # Test with access_code if column exists
      if QueueSession.column_names.include?("access_code")
        session2 = QueueSession.create!(
          venue: venue,
          status: "active",
          join_code: "222222",
          access_code: "333333"
        )

        # Mock to try existing codes first
        attempts = 0
        allow(SecureRandom).to receive(:random_number) do
          attempts += 1
          case attempts
          when 1 then 111111 # Existing join_code
          when 2 then 333333 # Existing access_code
          else 444444 # New unique code
          end
        end

        code = JoinCodeGenerator.generate
        expect(code).to eq("444444")
      end
    end
  end

  describe ".generate_unique_code" do
    it "is an alias for generate" do
      code = JoinCodeGenerator.generate_unique_code
      expect(code).to match(/^\d{6}$/)
    end

    it "generates unique codes just like generate" do
      codes = 10.times.map { JoinCodeGenerator.generate_unique_code }
      expect(codes.uniq.length).to eq(10)
    end
  end

  describe ".valid_format?" do
    context "with valid codes" do
      it "returns true for 6-digit codes" do
        expect(JoinCodeGenerator.valid_format?("123456")).to be true
        expect(JoinCodeGenerator.valid_format?("000000")).to be true
        expect(JoinCodeGenerator.valid_format?("999999")).to be true
      end

      it "accepts string input" do
        expect(JoinCodeGenerator.valid_format?("123456")).to be true
      end

      it "accepts numeric input and converts to string" do
        expect(JoinCodeGenerator.valid_format?(123456)).to be true
        # Note: 000001 in Ruby is interpreted as octal (1), so we use string "000001" instead
        expect(JoinCodeGenerator.valid_format?("000001")).to be true
        expect(JoinCodeGenerator.valid_format?(1)).to be false  # Single digit is not valid
      end
    end

    context "with invalid codes" do
      it "returns false for codes with wrong length" do
        expect(JoinCodeGenerator.valid_format?("12345")).to be false # Too short
        expect(JoinCodeGenerator.valid_format?("1234567")).to be false # Too long
        expect(JoinCodeGenerator.valid_format?("")).to be false # Empty
      end

      it "returns false for codes with non-digits" do
        expect(JoinCodeGenerator.valid_format?("12345a")).to be false
        expect(JoinCodeGenerator.valid_format?("a12345")).to be false
        expect(JoinCodeGenerator.valid_format?("123-456")).to be false
        expect(JoinCodeGenerator.valid_format?("12 456")).to be false
      end

      it "returns false for nil" do
        expect(JoinCodeGenerator.valid_format?(nil)).to be false
      end

      it "returns false for non-string/non-numeric input" do
        expect(JoinCodeGenerator.valid_format?([])).to be false
        expect(JoinCodeGenerator.valid_format?({})).to be false
      end
    end
  end

  describe ".find_active_session" do
    let!(:host_user) { User.create!(display_name: "Host", email: "host@example.com", password: "password", auth_provider: "general_user", role: :host) }
    let!(:venue1) { Venue.create!(name: "Venue 1", host_user_id: host_user.id) }
    let!(:venue2) { Venue.create!(name: "Venue 2", host_user_id: host_user.id) }
    let!(:active_session) do
      QueueSession.create!(
        venue: venue1,
        status: "active",
        join_code: "123456"
      )
    end
    let!(:paused_session) do
      QueueSession.create!(
        venue: venue2,
        status: "paused",
        join_code: "234567"
      )
    end
    let!(:ended_session) do
      QueueSession.create!(
        venue: venue1,
        status: "ended",
        join_code: "345678"
      )
    end

    context "with valid code" do
      it "finds active session by join_code" do
        session = JoinCodeGenerator.find_active_session("123456")
        expect(session).to eq(active_session)
      end

      it "finds active session by access_code if column exists" do
        if QueueSession.column_names.include?("access_code")
          active_with_access = QueueSession.create!(
            venue: venue1,
            status: "active",
            join_code: "456789",
            access_code: "567890"
          )

          session = JoinCodeGenerator.find_active_session("567890")
          expect(session).to eq(active_with_access)
        end
      end

      it "returns nil for non-active sessions" do
        expect(JoinCodeGenerator.find_active_session("234567")).to be_nil # Paused
        expect(JoinCodeGenerator.find_active_session("345678")).to be_nil # Ended
      end

      it "returns nil for non-existent code" do
        expect(JoinCodeGenerator.find_active_session("999999")).to be_nil
      end
    end

    context "with invalid code format" do
      it "returns nil without querying database" do
        # Should not make database queries for invalid formats
        expect(QueueSession).not_to receive(:active)
        
        expect(JoinCodeGenerator.find_active_session("12345")).to be_nil # Too short
        expect(JoinCodeGenerator.find_active_session("1234567")).to be_nil # Too long
        expect(JoinCodeGenerator.find_active_session("abcdef")).to be_nil # Non-digits
        expect(JoinCodeGenerator.find_active_session("")).to be_nil # Empty
        expect(JoinCodeGenerator.find_active_session(nil)).to be_nil # Nil
      end
    end
  end

  describe "private methods" do
    describe ".code_taken?" do
      let!(:host_user) { User.create!(display_name: "Host", email: "host@example.com", password: "password", auth_provider: "general_user", role: :host) }
      let!(:venue) { Venue.create!(name: "Test Venue", host_user_id: host_user.id) }

      it "checks if code is taken in join_code column" do
        QueueSession.create!(
          venue: venue,
          status: "active",
          join_code: "111111"
        )

        # We can test private method indirectly through generate
        attempts = 0
        allow(SecureRandom).to receive(:random_number) do
          attempts += 1
          attempts == 1 ? 111111 : 222222
        end

        code = JoinCodeGenerator.generate
        expect(code).to eq("222222")
        expect(attempts).to eq(2) # First attempt was taken, second succeeded
      end

      it "checks if code is taken in access_code column if it exists" do
        if QueueSession.column_names.include?("access_code")
          QueueSession.create!(
            venue: venue,
            status: "active",
            join_code: "333333",
            access_code: "444444"
          )

          attempts = 0
          allow(SecureRandom).to receive(:random_number) do
            attempts += 1
            case attempts
            when 1 then 444444 # Taken in access_code
            else 555555
            end
          end

          code = JoinCodeGenerator.generate
          expect(code).to eq("555555")
          expect(attempts).to eq(2)
        end
      end
    end
  end

  describe "thread safety" do
    it "can generate codes concurrently without issues" do
      codes = []
      mutex = Mutex.new

      threads = 10.times.map do
        Thread.new do
          5.times do
            code = JoinCodeGenerator.generate
            mutex.synchronize { codes << code }
          end
        end
      end

      threads.each(&:join)

      expect(codes.length).to eq(50)
      expect(codes).to all(match(/^\d{6}$/))
    end
  end
end

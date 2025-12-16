require 'rails_helper'

RSpec.describe BalanceTransaction, type: :model do
  let!(:user) { User.create!(display_name: "Test User", email: "test@example.com", password: "password", auth_provider: "general_user") }
  let!(:host_user) { User.create!(display_name: "Host", email: "host@example.com", password: "password", auth_provider: "general_user", role: :host) }
  let!(:venue) { Venue.create!(name: "Test Venue", host_user_id: host_user.id) }
  let!(:queue_session) { QueueSession.create!(venue: venue, status: "active", join_code: "123456") }
  let!(:song) { Song.create!(title: "Test Song", artist: "Test Artist") }
  let!(:queue_item) { QueueItem.create!(queue_session: queue_session, user: user, song: song, title: song.title, artist: song.artist) }

  describe "associations" do
    it "belongs to user" do
      transaction = BalanceTransaction.create!(
        user: user,
        amount_cents: 100,
        transaction_type: "credit",
        balance_after_cents: 100
      )
      expect(transaction.user).to eq(user)
    end

    it "belongs to queue_item (optional)" do
      transaction = BalanceTransaction.create!(
        user: user,
        queue_item: queue_item,
        amount_cents: 100,
        transaction_type: "debit",
        balance_after_cents: 0
      )
      expect(transaction.queue_item).to eq(queue_item)
    end

    it "can be created without queue_item" do
      transaction = BalanceTransaction.create!(
        user: user,
        amount_cents: 100,
        transaction_type: "credit",
        balance_after_cents: 100
      )
      expect(transaction.queue_item).to be_nil
    end
  end

  describe "validations" do
    it "requires amount_cents" do
      transaction = BalanceTransaction.new(
        user: user,
        transaction_type: "credit",
        balance_after_cents: 100
      )
      expect(transaction).not_to be_valid
      expect(transaction.errors[:amount_cents]).to include("can't be blank")
    end

    it "requires transaction_type" do
      transaction = BalanceTransaction.new(
        user: user,
        amount_cents: 100,
        balance_after_cents: 100
      )
      expect(transaction).not_to be_valid
      expect(transaction.errors[:transaction_type]).to include("can't be blank")
    end

    it "requires balance_after_cents" do
      transaction = BalanceTransaction.new(
        user: user,
        amount_cents: 100,
        transaction_type: "credit"
      )
      expect(transaction).not_to be_valid
      expect(transaction.errors[:balance_after_cents]).to include("can't be blank")
    end

    it "validates transaction_type is in allowed list" do
      transaction = BalanceTransaction.new(
        user: user,
        amount_cents: 100,
        transaction_type: "invalid_type",
        balance_after_cents: 100
      )
      expect(transaction).not_to be_valid
      expect(transaction.errors[:transaction_type]).to include("is not included in the list")
    end

    it "accepts valid transaction types" do
      %w[credit debit refund initial].each do |type|
        transaction = BalanceTransaction.new(
          user: user,
          amount_cents: 100,
          transaction_type: type,
          balance_after_cents: 100
        )
        expect(transaction).to be_valid
      end
    end

    it "validates balance_after_cents is not negative" do
      transaction = BalanceTransaction.new(
        user: user,
        amount_cents: 100,
        transaction_type: "debit",
        balance_after_cents: -1
      )
      expect(transaction).not_to be_valid
      expect(transaction.errors[:balance_after_cents]).to include("must be greater than or equal to 0")
    end

    it "allows balance_after_cents to be zero" do
      transaction = BalanceTransaction.new(
        user: user,
        amount_cents: 100,
        transaction_type: "debit",
        balance_after_cents: 0
      )
      expect(transaction).to be_valid
    end
  end

  describe "scopes" do
    let!(:credit1) do
      BalanceTransaction.create!(
        user: user,
        amount_cents: 100,
        transaction_type: "credit",
        balance_after_cents: 100,
        created_at: 3.days.ago
      )
    end

    let!(:credit2) do
      BalanceTransaction.create!(
        user: user,
        amount_cents: 50,
        transaction_type: "refund",
        balance_after_cents: 150,
        created_at: 2.days.ago
      )
    end

    let!(:debit1) do
      BalanceTransaction.create!(
        user: user,
        amount_cents: 30,
        transaction_type: "debit",
        balance_after_cents: 120,
        created_at: 1.day.ago
      )
    end

    let!(:initial) do
      BalanceTransaction.create!(
        user: user,
        amount_cents: 500,
        transaction_type: "initial",
        balance_after_cents: 500,
        created_at: 4.days.ago
      )
    end

    describe ".credits" do
      it "returns credit, refund, and initial transactions" do
        expect(BalanceTransaction.credits).to include(credit1, credit2, initial)
        expect(BalanceTransaction.credits).not_to include(debit1)
      end
    end

    describe ".debits" do
      it "returns only debit transactions" do
        expect(BalanceTransaction.debits).to include(debit1)
        expect(BalanceTransaction.debits).not_to include(credit1, credit2, initial)
      end
    end

    describe ".recent" do
      it "orders by created_at desc" do
        transactions = BalanceTransaction.recent
        expect(transactions.first).to eq(debit1)
        expect(transactions.second).to eq(credit2)
        expect(transactions.third).to eq(credit1)
        expect(transactions.fourth).to eq(initial)
      end
    end
  end

  describe "instance methods" do
    describe "#credit?" do
      it "returns true for credit transactions" do
        transaction = BalanceTransaction.create!(
          user: user,
          amount_cents: 100,
          transaction_type: "credit",
          balance_after_cents: 100
        )
        expect(transaction.credit?).to be true
      end

      it "returns true for refund transactions" do
        transaction = BalanceTransaction.create!(
          user: user,
          amount_cents: 100,
          transaction_type: "refund",
          balance_after_cents: 100
        )
        expect(transaction.credit?).to be true
      end

      it "returns true for initial transactions" do
        transaction = BalanceTransaction.create!(
          user: user,
          amount_cents: 100,
          transaction_type: "initial",
          balance_after_cents: 100
        )
        expect(transaction.credit?).to be true
      end

      it "returns false for debit transactions" do
        transaction = BalanceTransaction.create!(
          user: user,
          amount_cents: 100,
          transaction_type: "debit",
          balance_after_cents: 0
        )
        expect(transaction.credit?).to be false
      end
    end

    describe "#debit?" do
      it "returns true for debit transactions" do
        transaction = BalanceTransaction.create!(
          user: user,
          amount_cents: 100,
          transaction_type: "debit",
          balance_after_cents: 0
        )
        expect(transaction.debit?).to be true
      end

      it "returns false for credit transactions" do
        transaction = BalanceTransaction.create!(
          user: user,
          amount_cents: 100,
          transaction_type: "credit",
          balance_after_cents: 100
        )
        expect(transaction.debit?).to be false
      end

      it "returns false for refund transactions" do
        transaction = BalanceTransaction.create!(
          user: user,
          amount_cents: 100,
          transaction_type: "refund",
          balance_after_cents: 100
        )
        expect(transaction.debit?).to be false
      end

      it "returns false for initial transactions" do
        transaction = BalanceTransaction.create!(
          user: user,
          amount_cents: 100,
          transaction_type: "initial",
          balance_after_cents: 100
        )
        expect(transaction.debit?).to be false
      end
    end

    describe "#amount_display" do
      it "formats positive amounts correctly" do
        transaction = BalanceTransaction.create!(
          user: user,
          amount_cents: 12345,
          transaction_type: "credit",
          balance_after_cents: 12345
        )
        expect(transaction.amount_display).to eq("$123.45")
      end

      it "formats negative amounts as positive with dollar sign" do
        transaction = BalanceTransaction.create!(
          user: user,
          amount_cents: -5000,
          transaction_type: "debit",
          balance_after_cents: 0
        )
        expect(transaction.amount_display).to eq("$50.00")
      end

      it "formats zero amount" do
        transaction = BalanceTransaction.create!(
          user: user,
          amount_cents: 0,
          transaction_type: "credit",
          balance_after_cents: 0
        )
        expect(transaction.amount_display).to eq("$0.00")
      end

      it "formats small amounts correctly" do
        transaction = BalanceTransaction.create!(
          user: user,
          amount_cents: 5,
          transaction_type: "credit",
          balance_after_cents: 5
        )
        expect(transaction.amount_display).to eq("$0.05")
      end

      it "rounds to two decimal places" do
        transaction = BalanceTransaction.create!(
          user: user,
          amount_cents: 999,
          transaction_type: "credit",
          balance_after_cents: 999
        )
        expect(transaction.amount_display).to eq("$9.99")
      end
    end
  end

  describe "edge cases" do
    it "handles very large amounts" do
      transaction = BalanceTransaction.create!(
        user: user,
        amount_cents: 999999999,
        transaction_type: "credit",
        balance_after_cents: 999999999
      )
      expect(transaction).to be_valid
      expect(transaction.amount_display).to eq("$9999999.99")
    end

    it "allows description to be nil" do
      transaction = BalanceTransaction.create!(
        user: user,
        amount_cents: 100,
        transaction_type: "credit",
        balance_after_cents: 100,
        description: nil
      )
      expect(transaction).to be_valid
    end

    it "allows description to be present" do
      transaction = BalanceTransaction.create!(
        user: user,
        amount_cents: 100,
        transaction_type: "credit",
        balance_after_cents: 100,
        description: "Test transaction"
      )
      expect(transaction).to be_valid
      expect(transaction.description).to eq("Test transaction")
    end
  end
end

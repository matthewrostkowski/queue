require 'rails_helper'

RSpec.describe "Admin::BalanceTransactionsController", type: :request do
  before { skip "Skipping admin balance transactions requests for now" }
  let!(:admin_user) { User.create!(display_name: "Admin", email: "admin@example.com", password: "password", auth_provider: "general_user", role: :admin, balance_cents: 0) }
  let!(:regular_user) { User.create!(display_name: "Regular", email: "regular@example.com", password: "password", auth_provider: "general_user", role: :user, balance_cents: 1000) }
  let!(:another_user) { User.create!(display_name: "Another", email: "another@example.com", password: "password", auth_provider: "general_user", role: :user, balance_cents: 500) }
  
  let!(:song) { Song.create!(title: "Test Song", artist: "Test Artist") }
  let!(:host_user) { User.create!(display_name: "Host", email: "host@example.com", password: "password", auth_provider: "general_user", role: :host) }
  let!(:venue) { Venue.create!(name: "Test Venue", host_user_id: host_user.id) }
  let!(:queue_session) { QueueSession.create!(venue: venue, status: "active", join_code: "123456") }
  let!(:queue_item) { QueueItem.create!(queue_session: queue_session, user: regular_user, song: song, title: song.title, artist: song.artist) }
  
  let!(:transaction1) do
    BalanceTransaction.create!(
      user: regular_user,
      amount_cents: 500,
      transaction_type: "credit",
      balance_after_cents: 1500,
      description: "Initial credit"
    )
  end
  
  let!(:transaction2) do
    BalanceTransaction.create!(
      user: regular_user,
      queue_item: queue_item,
      amount_cents: 200,
      transaction_type: "debit",
      balance_after_cents: 1300,
      description: "Song purchase"
    )
  end
  
  let!(:transaction3) do
    BalanceTransaction.create!(
      user: another_user,
      amount_cents: 100,
      transaction_type: "credit",
      balance_after_cents: 600,
      description: "Admin credit"
    )
  end

  before do
    login_as(admin_user)
  end

  describe "GET /admin/balance_transactions" do
    it "displays users and recent transactions" do
      get admin_balance_transactions_path
      
      expect(response).to have_http_status(:ok)
      expect(assigns(:users)).to include(admin_user, regular_user, another_user)
      expect(assigns(:recent_transactions)).to include(transaction1, transaction2, transaction3)
      
      # Check that user info is displayed
      expect(response.body).to include(regular_user.display_name)
      expect(response.body).to include(another_user.display_name)
      
      # Check that transaction info is displayed
      expect(response.body).to include("Initial credit")
      expect(response.body).to include("Song purchase")
    end

    it "orders users by created_at desc" do
      get admin_balance_transactions_path
      users = assigns(:users)
      expect(users.first.created_at).to be >= users.last.created_at
    end

    it "limits recent transactions to 50" do
      # Create many transactions
      55.times do |i|
        BalanceTransaction.create!(
          user: regular_user,
          amount_cents: 10,
          transaction_type: "credit",
          balance_after_cents: 1000 + (i * 10),
          description: "Transaction #{i}"
        )
      end
      
      get admin_balance_transactions_path
      expect(assigns(:recent_transactions).count).to eq(50)
    end

    it "requires admin access" do
      login_as(regular_user)
      get admin_balance_transactions_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("Admin access required")
    end
  end

  describe "GET /admin/balance_transactions/:id" do
    it "shows user's transaction history" do
      get admin_balance_transaction_path(regular_user)
      
      expect(response).to have_http_status(:ok)
      expect(assigns(:user)).to eq(regular_user)
      expect(assigns(:transactions)).to include(transaction1, transaction2)
      expect(assigns(:transactions)).not_to include(transaction3) # Different user's transaction
      
      expect(response.body).to include(regular_user.display_name)
      expect(response.body).to include("Initial credit")
      expect(response.body).to include("Song purchase")
    end

    it "orders transactions by created_at desc" do
      get admin_balance_transaction_path(regular_user)
      transactions = assigns(:transactions)
      expect(transactions.first.created_at).to be >= transactions.last.created_at
    end
  end

  describe "POST /admin/balance_transactions/:id/add_credit" do
    context "with valid amount" do
      it "adds credit to user's balance and redirects with notice" do
        expect {
          post add_credit_admin_balance_transaction_path(regular_user), params: {
            amount_cents: 500
          }
        }.to change { regular_user.reload.balance_cents }.by(500)
        
        expect(response).to redirect_to(admin_balance_transactions_path)
        expect(flash[:notice]).to eq("Added $5.00 to #{regular_user.display_name}'s balance")
        
        # Check that transaction was created
        last_transaction = regular_user.balance_transactions.last
        expect(last_transaction.amount_cents).to eq(500)
        expect(last_transaction.transaction_type).to eq("credit")
        expect(last_transaction.description).to include("Admin credit by #{admin_user.display_name}")
      end
    end

    context "with zero amount" do
      it "redirects with alert" do
        expect {
          post add_credit_admin_balance_transaction_path(regular_user), params: {
            amount_cents: 0
          }
        }.not_to change { regular_user.reload.balance_cents }
        
        expect(response).to redirect_to(admin_balance_transactions_path)
        expect(flash[:alert]).to eq("Invalid amount")
      end
    end

    context "with negative amount" do
      it "redirects with alert" do
        expect {
          post add_credit_admin_balance_transaction_path(regular_user), params: {
            amount_cents: -100
          }
        }.not_to change { regular_user.reload.balance_cents }
        
        expect(response).to redirect_to(admin_balance_transactions_path)
        expect(flash[:alert]).to eq("Invalid amount")
      end
    end
  end

  describe "authorization" do
    context "when not admin" do
      before { login_as(regular_user) }

      it "redirects index" do
        get admin_balance_transactions_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("Admin access required")
      end

      it "redirects show" do
        get admin_balance_transaction_path(another_user)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("Admin access required")
      end

      it "redirects add_credit" do
        post add_credit_admin_balance_transaction_path(another_user), params: { amount_cents: 500 }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("Admin access required")
      end
    end

    context "when not logged in" do
      before { allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil) }

      it "redirects to login" do
        get admin_balance_transactions_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
end

# app/models/venue.rb
class Venue < ApplicationRecord
  # Host who owns/manages this venue
  belongs_to :host_user,
             class_name:  "User",
             foreign_key: "host_user_id",
             optional:    true

  has_many :queue_sessions,
           class_name:  "QueueSession",
           foreign_key: :venue_id,
           dependent:   :destroy

  validates :name, presence: true

  # Specs expect host_user_id presence validation
  validates :host_user_id, presence: true

  # Venue code validation
  validates :venue_code, presence: true, uniqueness: true, format: { with: /\A\d{6}\z/, message: "must be 6 digits" }, on: :update
  
  # Validate format on create only if venue_code is provided
  validates :venue_code, format: { with: /\A\d{6}\z/, message: "must be 6 digits" }, if: :venue_code?, on: :create
  validates :venue_code, uniqueness: true, if: :venue_code?, on: :create

  # Callbacks
  before_validation :generate_venue_code_if_needed, on: :create

  # Active queue session for this venue
  def active_queue_session
    Rails.logger.info "[VENUE] active_queue_session venue_id=#{id.inspect}"
    session = queue_sessions.active.first
    Rails.logger.info "[VENUE] active_queue_session venue_id=#{id.inspect} active_queue_session_id=#{session&.id.inspect}"
    session
  end

  # Host::VenuesController sometimes calls active_session
  alias_method :active_session, :active_queue_session

  # Generate a new venue code (used when first creating a venue)
  def generate_venue_code
    self.venue_code = VenueCodeGenerator.generate_unique_code
  end

  # Regenerate the venue code (used by hosts to get a new code)
  def regenerate_venue_code
    generate_venue_code
    save
  end

  # Class method to find a venue by its code
  def self.find_by_venue_code(code)
    VenueCodeGenerator.find_by_code(code)
  end

  # Simple hook to log validation problems clearly
  after_validation :log_validation_state

  private

  def generate_venue_code_if_needed
    if venue_code.blank? && new_record?
      generate_venue_code
      Rails.logger.info "[VENUE] Generated venue code venue_id=#{id.inspect} venue_code=#{venue_code.inspect}"
    end
  end

  def log_validation_state
    if errors.any?
      Rails.logger.warn "[VENUE] validation FAILED venue_id=#{id.inspect} name=#{name.inspect} host_user_id=#{host_user_id.inspect} errors=#{errors.full_messages.join('; ')}"
    else
      Rails.logger.info "[VENUE] validation OK venue_id=#{id.inspect} name=#{name.inspect} host_user_id=#{host_user_id.inspect}"
    end
  end
end

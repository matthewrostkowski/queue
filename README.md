# **Queue – Iteration 1 Team To-Do List**

### **Objective**

Deliver a working SaaS prototype that demonstrates Queue’s core value: live, social control over venue music.
Iteration 1 should:

* Run locally and deploy cleanly to **Heroku**
* Include **user stories (Cucumber)** and **RSpec tests**
* Implement the **core five screens**
* Follow **MVC**, **BDD/TDD**, and **DRY** best practices from ESaaS.

---

## **1. Submission Checklist**

✅ Deliver the following in your CourseWorks submission:

1. **README**

   * Team names + UNIs
   * Install/run/test/deploy instructions
   * Environment variables (Spotify API keys, etc.)
   * Heroku URL + GitHub link
2. **Cucumber features**

   * At least one story per core flow
   * Written in stakeholder language (`As a [role], I want to… so that …`)
3. **RSpec tests**

   * Cover models and controllers you built
   * Follow the FIRST principles (Fast, Independent, Repeatable, Self-checking, Timely)
4. **MVP prototype**

   * Demonstrates core functionality and passes all tests
5. **Heroku deployment**

   * No 500 errors on main routes

---

## **2. Core Pages / Features**

Below each section is organized by page and shows what’s needed for Iteration 1.

---

### **2.1 Login / Auth Screen**

**Goal:** Allow users to sign in with Spotify or continue as guest.
**Behavior:** User lands on Login screen → authenticates → navigates to Search page.

**Code Tasks**

* Reuse existing `LoginScreen.tsx` OAuth logic.
* Create `User` model in Rails (id, display_name, auth_provider, access_token).
* `POST /session` → creates or returns a user record.

**BDD ( Cucumber )**
*As a new patron, I want to log in to Queue so that I can control the music at my venue.*

**TDD ( RSpec )**

* Validate that a User must have an identifier.
* Controller spec ensures `POST /session` returns 200 + JSON.

**README Notes**

* Document required Spotify credentials and redirect URI.

---

### **2.2 Scan QR / Join Venue**

**Goal:** Let user join a venue’s active queue by scanning a code.
**Behavior:** User scans QR → joins venue → app stores venue_id + queue_session_id.

**Code Tasks**

* Rails: create `Venue` (name, address) and `QueueSession` (venue_id, is_active).
* `GET /venues/:id` → returns venue and active queue info.
* Client: mock camera scan or “Join Demo Venue” button.
* Associate user → queue in state.

**BDD Scenario**
*As a patron, I want to join my venue’s queue by scanning a code so that my song choices affect this room.*

**TDD Tests**

* Model: `QueueSession` must belong_to a `Venue`.
* Controller: GET `/venues/:id` returns venue JSON.

**README Notes**

* Explain how TA can simulate scan action.

---

### **2.3 Song Search Page (Core Value Prop)**

**Goal:** User searches for songs and adds to queue.
**Behavior:** Type song name → see results (title, artist, cover) → tap “Add to Queue.”

**Code Tasks**

* Client: `/songs/search?q=` fetch + render list with “Add to Queue.”
* Server: `SongsController#search` (stub 3–5 songs or Spotify proxy).
* `QueueItem` model: song_id, queue_session_id, user_id, base_price.
* Add simple `price_for_display` method that increases price if demand is high (1–2 lines is fine).

**BDD Scenario**
*As a patron, I want to search and queue a song so that I can hear it play at my venue.*

**TDD Tests**

* Unit: `price_for_display` adjusts for demand.
* Controller: POST `/queue_items` returns 201 with JSON.

**README Notes**

* Include sample seed songs and demo venue setup.

---

### **2.4 Queue Screen (Vote / Dynamic Ordering)**

**Goal:** Show current queue and let users upvote/downvote songs.
**Behavior:** View list → tap upvote → song moves higher.

**Code Tasks**

* Extend existing `QueueScreen.tsx`: add Upvote / Downvote buttons.
* Rails: add `vote_count` to `QueueItem`; PATCH `/queue_items/:id/vote`.
* Sort queue by `base_priority + vote_count`.

**BDD Scenario**
*As a guest, I want to upvote songs so that popular songs play sooner.*

**TDD Tests**

* Model: vote count adjusts correctly.
* Controller: PATCH `/vote` updates and returns new score.

**README Notes**

* Explain how TA can navigate to Queue screen and test voting behavior.

---

### **2.5 User Profile Page**

**Goal:** Show user’s contribution (summary stats).
**Behavior:** Display username, songs queued, total upvotes.

**Code Tasks**

* Client: simple Profile screen.
* Server: `/users/:id/summary` → aggregates queue activity.

**BDD Scenario**
*As a user, I want to see how many songs I’ve added and upvotes earned.*

**TDD Tests**

* Controller spec checks aggregate counts returned correctly.

**README Notes**

* Include sample User and example endpoint response.

---

## **3. Testing (BDD + TDD)**

* Every core feature must have a Cucumber story and RSpec tests.
* Use **Red → Green → Refactor** cycle: write failing spec → implement → cleanup.
* Keep tests fast and independent (no Spotify API calls in tests).
* Ensure `bundle exec rspec` and `bundle exec cucumber` both pass.

---

## **4. Rails / MVC Structure**

**Models:** User, Venue, QueueSession, Song, QueueItem
**Associations:**

* Venue has_many QueueSessions
* QueueSession has_many QueueItems
* QueueItem belongs_to Song and User

**Routes:**

* `SongsController#search`
* `QueueItemsController#create` and `#vote`
* `VenuesController#show`
* `UsersController#summary`
* `SessionsController#create`

**Best Practices:**

* Business logic (price/votes) → Model.
* Keep controllers thin, views simple.
* Apply validations (e.g., QueueItem must have song and queue_session).
* Use `before_action` filter to load `current_user` and `current_queue_session`.

---

## **5. Deployment + Documentation**

* **Heroku:** Confirm API endpoints respond without errors.
* **Seeds:** Create demo venue, songs, user, and queue items.
* **README:** Exact steps:

  ```
  git clone …  
  bundle install  
  rails db:setup  
  bundle exec rspec  
  bundle exec cucumber  
  rails server
  ```
* Include GitHub repo URL and Heroku URL in submission.

---

## **6. Roles and Next Actions**

**Backend Lead** – Rails models, controllers, Heroku deploy.
**Frontend Lead** – React Native screens and navigation.
**Testing Lead** – RSpec and Cucumber coverage.
**Documentation Lead** – README and submission materials.

**Team Process:**

* Pair program on complex tasks (OAuth, pricing logic).
* Commit frequently with clear messages.
* Merge only when tests pass.
* Focus on behavior first, polish later.

---

### **Rubric Mapping**

* **User Stories (Cucumber):** 40%
* **Working Prototype:** 20%
* **RSpec Coverage:** 30%
* **Deployment + README:** 10%

---



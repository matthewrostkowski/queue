

# **Queue: "Queue it. Upvote it. Hear it"**

### **Team Members**
- **Matt Gatune** - mkg2170
- **Jonah Aden** - jka2154
- **Tzu-An Cheng** - tc3497
- **Matthew Rostkowski** - mcr2225

### **Project Overview**

**Pain Points We're Addressing:**
- **For the Customer:** The lack of control over the music at venues
- **For the Venue Owner:** Music (ex. DJs) is a fixed cost with no guaranteed profit/customer engagement, or return. Instead of music being a cost for owners, it is now an additional source of profit
- **For the DJ:** Difficulty in guessing the crowd's taste without any real-time tools

**What Our SaaS Does:**
- **Interactive Control:** Patrons can choose, pay for, and upvote songs in real time, influencing the playback order
- **Surge Pricing / Market Mechanism:** Song prices adjust in real time based on demand, time, and location, transforming music from a cost center into a revenue stream
- **Social & Data Insights:** DJs receive real-time data on which songs are being requested and upvoted, aiding in selection decisions
- **Seamless Integration:** Fully digital — no hardware, venues connect their speakers and playlist through the Spotify API

**Why We're Unique:**
- Queue Management & Upvote Function
- Multiple Music Provider Integration
- Logical for Bars
- Logical for Clubs
- Market Component for Making Money
- All of the above are bound into one streamlined app that is intuitive to use

**Video Demo:** https://youtu.be/P19SGGUauF8?si=UQ9la7P8lGKR9cKh

### **Deployment**
- **Heroku URL**: https://queuemusic-app-a824d0f49ec6.herokuapp.com/login
- **GitHub Repository**: https://github.com/[your-username]/queuemusic

### **Project Summary**
Queue is a social music control system for venues. Patrons can join venue queues, search for songs, add them to the queue, and vote on songs to influence play order. This iteration includes:

- ✅ **Authentication System**: Guest login and email/password registration
- ✅ **User Profiles**: View queue statistics and contribution history  
- ✅ **Queue Management**: Add songs and vote on queue items
- ✅ **Venue System**: Join venue queues via QR codes
- ✅ **Comprehensive Testing**: 32 RSpec tests + 15 Cucumber scenarios (100% passing)
- ✅ **59% Test Coverage**: Well-tested core functionality

---

## **Setup Instructions**

### **Objective**

Get Queue running locally for development and testing.
This guide walks through environment setup, dependency installation, database initialization, and test verification.

---

## **1. Install Ruby + Bundler**

Ensure you’re using:

* **Ruby:** 3.3.8
* **Bundler:** 2.7.2

**Commands:**

```bash
rbenv install 3.3.8
rbenv local 3.3.8
gem install bundler -v 2.7.2
rbenv rehash
```

---

## **2. Install Dependencies**

From the **project root**, run:

```bash
bundle _2.7.2_ install
```

This installs all required gems listed in the `Gemfile`.

---

## **3. Set Up the Database**

Initialize your local database:

```bash
bin/rails db:create
bin/rails db:migrate
```

recreate your local database:

```bash
rm -f storage/development.sqlite3 storage/test.sqlite3
bin/rails db:create
bin/rails db:schema:load
RAILS_ENV=test bin/rails db:create
RAILS_ENV=test bin/rails db:schema:load
```

**Optional:** Load demo or seed data if available.

```bash
bin/rails db:seed
```

---

## **4. Run the Server**

Start your local Rails server:

```bash
bin/rails server
```

Then open the app in your browser:
👉 [http://localhost:3000](http://localhost:3000)

---

## **5. Run Tests (Confirm Environment Works)**

Verify setup and ensure tests pass:

```bash
bundle exec rspec
bundle exec cucumber
```

You should see:

> “0 examples, 0 failures” if it’s a fresh setup.

---

## **6. Notes**

* **Rails version:** 8.0.0
* **Ruby version:** 3.3.8
* **Databases:**

  * SQLite (development)
  * Postgres (production)
* **Test frameworks:** RSpec + Cucumber

---

## **7. Deployment (Heroku)**

### **Quick Deploy**
```bash
# Install Heroku CLI first: https://devcenter.heroku.com/articles/heroku-cli
heroku create your-app-name
git push heroku main
heroku run rails db:migrate
heroku run rails db:seed  # Optional: load demo data
heroku open
```

### **Environment Setup**
The app is configured for Heroku with:
- ✅ `Procfile` for Puma web server
- ✅ PostgreSQL for production database  
- ✅ SQLite for development/test
- ✅ Rails 8.0 + Ruby 3.3.4

---
# Login function

## Pages & Routing Overview

### App Pages
- **Login Page** — `GET /` (alias: `GET /login`)  
  *Controller:* `LoginController#index`  
  *Notes:* Landing with **two** forms: (1) general user sign-in (email/password), (2) Continue as Guest.
- **Signup Page** — `GET /signup`  
  *Controller:* `UsersController#new`  
  *Notes:* Registration form for general users.
- **Main Page** — `GET /mainpage`  
  *Controller:* `MainController#index`  
  *Notes:* Post-login landing. Navbar shows `Main / Scan / Search / Profile` + current user + Logout.
- **Scan Page** — `GET /scan`  
  *Controller:* `ScanController#index`  
  *Notes:* Placeholder for QR scanning UI.
- **Search Page** — `GET /search`  
  *Controller:* `SearchController#index`  
  *Notes:* Placeholder for upcoming song search.
- **Profile Page** — `GET /profile`  
  *Controller:* `ProfilesController#show`  
  *Notes:* Requires login; shows stub card for future user stats.

### Auth Endpoints
- **Create Session (login)** — `POST /session`  
  *Controller:* `SessionsController#create`  
  *HTML:* Redirects to `/mainpage` on success (guest or general_user).  
  *JSON:* `{ id, display_name, provider }` with `200 OK` (error → `401`).
- **Destroy Session (logout)** — `DELETE /logout`  
  *Controller:* `SessionsController#destroy`  
  *HTML:* `303 See Other` → `/login`.  
  *JSON:* `204 No Content`.
- **Create User (signup)** — `POST /users`  
  *Controller:* `UsersController#create`  
  *HTML:* On success → `/mainpage`; on failure re-renders with errors.

### Current Flow
1. `GET /login` → dual forms (general user sign-in **and** guest).
2. **Guest:** POST `/session` with `provider=guest` → create a *new* `User` (guest) → `/mainpage`.
3. **General User:**  
   - **Sign up:** `GET /signup` → `POST /users` (email/password) → `/mainpage`.  
   - **Sign in:** `POST /session` with `provider=general_user` → auth via `has_secure_password` → `/mainpage`.
4. Header adapts to login state; `DELETE /logout` always returns to `/login`.

### Access Control
- `ApplicationController` sets `current_user` from `session[:user_id]`.
- `before_action :authenticate_user!` protects app pages (Main/Scan/Search/Profile).  
  Exemptions: `Login#index`, `Users#new`, `Users#create`, `Sessions#create`, `Sessions#destroy`.
- No-store headers applied to avoid back/forward cache showing stale protected pages.

---

## Controllers (implemented/touched)
- `LoginController#index` — renders login page; redirects to `/mainpage` if already signed in.
- `SessionsController#create|destroy` — handles guest and general_user login + logout.
- `UsersController#new|create` — signup for general users.
- `MainController#index`, `ScanController#index`, `SearchController#index`, `ProfilesController#show` — protected placeholders / stubs.

---

## Models
- **User**
  - Associations: `has_many :queue_items, dependent: :nullify`
  - Auth:
    - `has_secure_password validations: false`
    - Providers: `"guest"` (no email/password required), `"general_user"` (email+password required)
  - Validations:
    - `auth_provider`: presence
    - `display_name`: presence
    - When `auth_provider == "general_user"`:
      - `email`: presence, RFC format; downcased before save
      - `password`: presence & `min: 8` (via custom `password_required?`)
  - Callbacks: `before_save :downcase_email`

---

## Database (current essentials)
- `users`:
  - `id` (PK, implicit), `display_name`, `auth_provider` (default `"guest"`), `email` (nullable for guest), `password_digest` (nullable for guest), timestamps
  - Index: `index_users_on_lower_email` (unique on `LOWER(email)`) for general_user
- (stubs for future): `songs`, `venues`, `queue_sessions`, `queue_items` — created earlier per schema; not yet wired in UI.

---

## Views (key templates)
- `app/views/login/index.html.erb`
  - Left column: **Sign in** (POST `/session`, `provider=general_user`, fields: `email`, `password`)
  - Right column: **Continue as Guest** (POST `/session`, `provider=guest`, optional `display_name`)
- `app/views/users/new.html.erb` — Signup form (`email`, `password`, `password_confirmation`, optional `display_name`)
- Layout header shows conditional nav & Logout link.

---

## Tests

### Cucumber (BDD)
- **`features/login.feature`**
  - Guest sign-in happy path → lands on `/mainpage`, shows guest name.
  - Redirect rules: logged-in visiting `/login` → `/mainpage`.
- **`features/signup_and_login.feature`**
  - **Sign up** general user (email/password) → `/mainpage`.
  - **Sign in** general user with valid/invalid password.
- **Common steps**
  - `features/step_definitions/web_steps.rb` — `I visit`, `I fill in`, `I press`, page assertions.
  - `features/step_definitions/session_steps.rb` — `I am logged out`, `I am logged in as "..."`.
  - `features/support/selectors.rb` — helpers/selectors used by steps.

### RSpec (TDD)
- **`spec/models/user_spec.rb`**
  - Guest valid without email/password.
  - General user requires email/password; email is downcased.
- **`spec/requests/password_auth_spec.rb`**
  - `POST /users` creates general user & logs in.
  - `POST /session` general_user success/invalid password cases.
- **`spec/requests/sessions_spec.rb`**
  - Guest login sets session and redirects.
  - Logout clears session and redirects to `/login`.
  - Same display_name guest logins create distinct user IDs.

---

## Routing Summary
| Route           | Verb   | Controller#Action        | Purpose                                  |
|-----------------|--------|--------------------------|------------------------------------------|
| `/`             | GET    | `login#index`            | Login/Landing (redirect if signed in)    |
| `/login`        | GET    | `login#index`            | Alias of `/`                              |
| `/signup`       | GET    | `users#new`              | Sign up form                              |
| `/users`        | POST   | `users#create`           | Create account (general_user)             |
| `/session`      | POST   | `sessions#create`        | Login (guest or general_user)             |
| `/logout`       | DELETE | `sessions#destroy`       | Logout                                    |
| `/mainpage`     | GET    | `main#index`             | Post-login main page                      |
| `/scan`         | GET    | `scan#index`             | QR scan placeholder                        |
| `/search`       | GET    | `search#index`           | Song search placeholder                    |
| `/profile`      | GET    | `profiles#show`          | User profile (requires login)              |

---

## Current Behavior Guarantees
- Guest login never requires password and always creates a **new** user (unique `id`) even with same `display_name`.
- General user login uses `email + password` with bcrypt hashing (`has_secure_password`).
- All protected pages force authentication; back/forward cache is mitigated via no-store headers.


-------

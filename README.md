

# Queue

**"Queue it. Upvote it. Hear it."**
**Proj-iter-2**

---

## 📌 Overview / General Information

### **Team Members**

* Matt Gatune — **mkg2170**
* Jonah Aden — **jka2154**
* Tzu-An Cheng — **tc3497**
* Matthew Rostkowski — **mcr2225**

---

## 🎤 Project Overview

### **Pain Points We're Addressing**

**For the Customer:**

* Lack of control over the music at venues.

**For the Venue Owner:**

* Music (e.g., DJs) is a fixed cost with no guaranteed profit, engagement, or return.
* With Queue, music becomes an additional **revenue stream**, not a cost center.

**For the DJ:**

* Difficulty understanding a crowd’s taste without real-time insight tools.

---

## 🎧 What Our SaaS Does

### **Interactive Control**

Patrons can choose, pay for, and upvote songs in real time, directly influencing playback order.

### **Surge Pricing / Market Mechanism**

Song prices adjust in real time based on demand, time, and location — turning music into a dynamic profit mechanism.

### **Social & Data Insights**

DJs get real-time visibility into requested and upvoted songs, enabling informed selection decisions.

### **Seamless Integration**

Fully digital system: venues connect their speakers and playlists using the **Spotify API**.

---

## 💡 Why We're Unique

* Queue Management & Upvote Function
* Integration Across Multiple Music Providers
* Built for Bars
* Built for Clubs
* Market-based pricing model
* All combined into **one intuitive, streamlined app**

### 🎥 Video Demo

[https://youtu.be/P19SGGUauF8?si=UQ9la7P8lGKR9cKh](https://youtu.be/P19SGGUauF8?si=UQ9la7P8lGKR9cKh)

---

# 🧩 Proj-iter-2 Specific Information

### **Deployment (Heroku)**

[https://queuemusic-app-a824d0f49ec6.herokuapp.com/](https://queuemusic-app-a824d0f49ec6.herokuapp.com/)

### **GitHub Repository**

[https://github.com/matthewrostkowski/queuemusic/](https://github.com/matthewrostkowski/queuemusic/)

---

## 📈 Iteration Summary

In this iteration, we made significant progress moving Queue from an MVP stage to implementing core functionality needed for production readiness.

We built:

* Full account creation, including Google authentication
* Clear delineation between **users** (venue goers), **hosts** (venue owners), and **admin** (our team)
* Major progress on core functionality such as song playing and pricing
* Initial rollout of our UI schema across pages

---

## ✅ Completed Features (Iteration 2)

* **Authentication**
* **User Profiles / Google Sign-In**
* **Queue Management & Song Playback**
* **Venue System:** Join venue queues via 6-digit codes
* **User / Host / Admin Role System**
* **Pricing Simulation**
* **Testing:** RSpec tests + Cucumber scenarios - 100% passing

---

## 🛠️ Running Instructions

To run all RSpec tests:

bundle exec rspec


To run all Cucumber feature tests:

bundle exec cucumber

If you have trouble navigating to specific pages, open:

```
localhost:3000/<page-name>
```

Example:

```
localhost:3000/host
```



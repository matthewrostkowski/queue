// Example JavaScript for automatic track progression
// Add this to your audio player component

class QueuePlayer {
  constructor() {
    this.audio = document.getElementById('audio-player'); // Your audio element
    this.setupEventListeners();
  }

  setupEventListeners() {
    // When a track ends, automatically progress to next
    this.audio.addEventListener('ended', () => {
      this.handleTrackEnded();
    });

    // Optional: Handle errors
    this.audio.addEventListener('error', (e) => {
      console.error('Audio error:', e);
      this.handleTrackEnded(); // Skip to next on error
    });
  }

  async handleTrackEnded() {
    try {
      const response = await fetch('/queue/track_ended', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      });

      const data = await response.json();

      if (data.success && data.now_playing) {
        // Smoothly transition to next track
        this.playTrack(data.now_playing);
        this.updateUI(data.now_playing);
      } else {
        // Queue finished
        console.log('Queue finished!');
        this.updateUI(null);
      }
    } catch (error) {
      console.error('Error progressing to next track:', error);
    }
  }

  playTrack(trackData) {
    // Set the new audio source
    this.audio.src = trackData.song.audio_url;
    
    // Play immediately for smooth transition
    this.audio.play().catch(error => {
      console.error('Playback error:', error);
    });
  }

  updateUI(trackData) {
    // Update your UI with current track info
    if (trackData) {
      document.getElementById('now-playing-title').textContent = trackData.song.title;
      document.getElementById('now-playing-artist').textContent = trackData.song.artist;
      
      // Update queue display to refresh positions
      this.refreshQueue();
    } else {
      // Clear now playing
      document.getElementById('now-playing-title').textContent = 'No track playing';
      document.getElementById('now-playing-artist').textContent = '';
    }
  }

  async refreshQueue() {
    // Optionally refresh the queue display to show updated order
    try {
      const response = await fetch('/queue.json');
      const data = await response.json();
      this.renderQueueItems(data.queue_items);
    } catch (error) {
      console.error('Error refreshing queue:', error);
    }
  }

  renderQueueItems(queueItems) {
    // Render queue items in order of vote score
    const queueList = document.getElementById('queue-list');
    queueList.innerHTML = '';

    queueItems.forEach((item, index) => {
      const queueItem = document.createElement('div');
      queueItem.className = 'queue-item';
      queueItem.innerHTML = `
        <span class="position">#${index + 1}</span>
        <span class="title">${item.song.title}</span>
        <span class="artist">${item.song.artist}</span>
        <span class="votes">${item.vote_score} votes</span>
      `;
      queueList.appendChild(queueItem);
    });
  }

  // Manual skip to next track
  async skipToNext() {
    try {
      const response = await fetch('/queue/next_track', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      });

      const data = await response.json();

      if (data.success && data.now_playing) {
        this.playTrack(data.now_playing);
        this.updateUI(data.now_playing);
      }
    } catch (error) {
      console.error('Error skipping track:', error);
    }
  }

  // Start playback
  async startPlayback() {
    try {
      const response = await fetch('/queue/start_playback', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      });

      const data = await response.json();

      if (data.success && data.now_playing) {
        this.playTrack(data.now_playing);
        this.updateUI(data.now_playing);
      }
    } catch (error) {
      console.error('Error starting playback:', error);
    }
  }
}

// Initialize the player
document.addEventListener('DOMContentLoaded', () => {
  const player = new QueuePlayer();

  // Wire up buttons
  document.getElementById('start-playback-btn')?.addEventListener('click', () => {
    player.startPlayback();
  });

  document.getElementById('skip-btn')?.addEventListener('click', () => {
    player.skipToNext();
  });
});

// Optional: Poll for queue updates every 5 seconds to catch vote changes
setInterval(async () => {
  try {
    const response = await fetch('/queue/current_track');
    const data = await response.json();
    // Update UI if needed
  } catch (error) {
    console.error('Error polling current track:', error);
  }
}, 5000);
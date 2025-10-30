/**
 * Queue Player - Deezer Preview Playback with HTML5 Audio
 * Handles dynamic queue playback with real-time reordering
 */

class QueuePlayer {
  constructor() {
    this.audio = new Audio();
    this.isPlaying = false;
    this.currentTrack = null;
    this.queueData = [];
    this.pollInterval = null;
    
    this.initElements();
    this.initAudioPlayer();
    this.startPolling();
  }

  initElements() {
    // Buttons
    this.playQueueBtn = document.getElementById('playQueueBtn');
    this.playPauseBtn = document.getElementById('playPauseBtn');
    this.nextBtn = document.getElementById('nextBtn');
    this.prevBtn = document.getElementById('prevBtn');
    
    // Now playing bar elements
    this.nowPlayingBar = document.getElementById('nowPlayingBar');
    this.npAlbum = document.getElementById('npAlbum');
    this.npTitle = document.getElementById('npTitle');
    this.npArtist = document.getElementById('npArtist');
    this.progressFill = document.getElementById('progressFill');
    
    // Queue list
    this.queueList = document.getElementById('queueList');
    
    // Event listeners
    this.playQueueBtn.addEventListener('click', () => this.startQueue());
    this.playPauseBtn.addEventListener('click', () => this.togglePlayPause());
    this.nextBtn.addEventListener('click', () => this.playNext());
    this.prevBtn.addEventListener('click', () => this.playPrevious());
  }

  initAudioPlayer() {
    // Audio event listeners
    this.audio.addEventListener('ended', () => {
      console.log('Track ended, playing next...');
      this.playNext();
    });

    this.audio.addEventListener('timeupdate', () => {
      this.updateProgress();
    });

    this.audio.addEventListener('play', () => {
      this.isPlaying = true;
      this.updatePlayPauseButton();
    });

    this.audio.addEventListener('pause', () => {
      this.isPlaying = false;
      this.updatePlayPauseButton();
    });

    this.audio.addEventListener('error', (e) => {
      console.error('Audio error:', e);
      alert('Failed to play audio. Preview may not be available.');
    });
  }

  async startQueue() {
    try {
      this.playQueueBtn.disabled = true;
      this.playQueueBtn.querySelector('#playBtnText').textContent = 'Starting...';
      
      const response = await fetch('/queue/start_playback', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      });
      
      const data = await response.json();
      
      if (data.success) {
        await this.playTrack(data.track);
        this.showNowPlayingBar();
        this.updatePlayQueueButton(true);
      } else {
        alert(data.message || 'Failed to start queue');
        this.playQueueBtn.disabled = false;
      }
    } catch (error) {
      console.error('Error starting queue:', error);
      alert('Failed to start playback');
      this.playQueueBtn.disabled = false;
    }
  }

  async playTrack(track) {
    if (!track.preview_url) {
      console.error('No preview URL available for track:', track);
      alert('No preview available for this track');
      return;
    }

    console.log('Playing track:', track);
    
    try {
      // Stop current playback
      this.audio.pause();
      
      // Load new track
      this.audio.src = track.preview_url;
      this.audio.load();
      
      // Play
      await this.audio.play();
      
      // Update UI
      this.currentTrack = track;
      this.npTitle.textContent = track.title;
      this.npArtist.textContent = track.artist;
      this.npAlbum.style.backgroundImage = `url('${track.cover_url}')`;
      
      this.highlightCurrentTrack(track.id);
      this.isPlaying = true;
      this.updatePlayPauseButton();
      
    } catch (error) {
      console.error('Error playing track:', error);
      alert('Failed to play track');
    }
  }

  async playNext() {
    try {
      const response = await fetch('/queue/next_track', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      });
      
      const data = await response.json();
      
      if (data.success && data.track) {
        await this.playTrack(data.track);
      } else {
        console.log('No more tracks in queue');
        this.stopPlayback();
      }
    } catch (error) {
      console.error('Error playing next track:', error);
    }
  }

  async playPrevious() {
    // Restart current track
    this.audio.currentTime = 0;
    this.audio.play();
  }

  async togglePlayPause() {
    if (this.isPlaying) {
      this.audio.pause();
    } else {
      this.audio.play();
    }
  }

  async stopPlayback() {
    try {
      await fetch('/queue/stop_playback', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      });
      
      this.audio.pause();
      this.audio.src = '';
      
      this.isPlaying = false;
      this.currentTrack = null;
      this.hideNowPlayingBar();
      this.updatePlayQueueButton(false);
    } catch (error) {
      console.error('Error stopping playback:', error);
    }
  }

  // Polling for queue updates
  startPolling() {
    // Poll every 2 seconds for queue state updates
    this.pollInterval = setInterval(() => this.pollQueueState(), 2000);
  }

  async pollQueueState() {
    try {
      const response = await fetch('/queue/state');
      const data = await response.json();
      
      this.updateQueueDisplay(data.queue);
      
      // If a track was voted up and should now play
      if (data.is_playing && data.currently_playing) {
        const topTrack = data.queue[0];
        if (topTrack && this.currentTrack && topTrack.id !== this.currentTrack.id) {
          console.log('Queue order changed, switching track...');
          await this.playTrack(topTrack);
          
          // Tell backend to update currently playing
          await fetch('/queue/next_track', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': this.getCSRFToken()
            }
          });
        }
      }
    } catch (error) {
      console.error('Error polling queue state:', error);
    }
  }

  updateQueueDisplay(newQueue) {
    const queueItems = Array.from(document.querySelectorAll('.queue-item'));
    
    // Create a map of current positions
    const currentPositions = new Map();
    queueItems.forEach((item, index) => {
      const id = parseInt(item.dataset.queueItemId);
      currentPositions.set(id, index);
    });
    
    // Create a map of new positions
    const newPositions = new Map();
    newQueue.forEach((item, index) => {
      newPositions.set(item.id, index);
    });
    
    // Find items that moved up
    newQueue.forEach((item, newIndex) => {
      const oldIndex = currentPositions.get(item.id);
      if (oldIndex !== undefined && newIndex < oldIndex) {
        // Item moved up - animate it
        const element = document.querySelector(`[data-queue-item-id="${item.id}"]`);
        if (element) {
          this.animateItemMovedUp(element);
        }
      }
    });
    
    // Reorder the DOM elements smoothly
    setTimeout(() => {
      const sortedItems = newQueue.map(item => {
        return document.querySelector(`[data-queue-item-id="${item.id}"]`);
      }).filter(el => el !== null);
      
      sortedItems.forEach(item => {
        this.queueList.appendChild(item);
      });
    }, 300);
  }

  animateItemMovedUp(element) {
    // Add green glow animation class
    element.classList.add('moving-up');
    
    // Remove after animation completes
    setTimeout(() => {
      element.classList.remove('moving-up');
    }, 1000);
  }

  highlightCurrentTrack(trackId) {
    // Remove previous highlight
    document.querySelectorAll('.queue-item').forEach(item => {
      item.classList.remove('currently-playing');
    });
    
    // Add highlight to current track
    const currentElement = document.querySelector(`[data-queue-item-id="${trackId}"]`);
    if (currentElement) {
      currentElement.classList.add('currently-playing');
    }
  }

  updateProgress() {
    if (this.audio.duration) {
      const progress = (this.audio.currentTime / this.audio.duration) * 100;
      this.progressFill.style.width = `${progress}%`;
    }
  }

  updatePlayPauseButton() {
    this.playPauseBtn.textContent = this.isPlaying ? '⏸' : '▶';
  }

  updatePlayQueueButton(isPlaying) {
    const icon = this.playQueueBtn.querySelector('#playBtnIcon');
    const text = this.playQueueBtn.querySelector('#playBtnText');
    
    if (isPlaying) {
      icon.textContent = '⏸';
      text.textContent = 'Playing';
      this.playQueueBtn.classList.add('playing');
    } else {
      icon.textContent = '▶';
      text.textContent = 'Play Queue';
      this.playQueueBtn.classList.remove('playing');
    }
    
    this.playQueueBtn.disabled = false;
  }

  showNowPlayingBar() {
    this.nowPlayingBar.classList.remove('hidden');
  }

  hideNowPlayingBar() {
    this.nowPlayingBar.classList.add('hidden');
  }

  getCSRFToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.content : '';
  }

  destroy() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
    }
    if (this.audio) {
      this.audio.pause();
      this.audio.src = '';
    }
  }
}

// Export for use in HTML
window.QueuePlayer = QueuePlayer;
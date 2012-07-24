
class Timer {
 
  int savedTime; // When Timer started
  int totalTime; // How long Timer should last
  boolean timerRunning = false;
  
  Timer(int tempTotalTime) {
    totalTime = tempTotalTime;
  }
  
  // Starting the timer
  void start() {
    // When the timer starts it stores the current time in milliseconds.
    savedTime = millis();
   timerRunning = true;
  }
  
  void stop() {
    timerRunning = false;
  }
  
  // The function isFinished() returns true if 5,000 ms have passed. 
  // The work of the timer is farmed out to this method.
  boolean isFinished() { 
    if (!timerRunning) { 
      return true;
    }
    // Check how much time has passed
    int passedTime = millis()- savedTime;
    if (passedTime > totalTime) {
      return true;
    } else {
      return false;
    }
  }
}

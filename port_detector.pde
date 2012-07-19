import processing.serial.*;


class PortDetector {
  
  int detectionInterval = 1 * 1000;  // 10 seconds
  Timer timer = new Timer(detectionInterval);
  String[] ports = Serial.list();
  Serial[] serials = new Serial[ports.length];
  boolean portInitializationInProgress = false;
  boolean spectruinoDetectionInProgress = false;
  boolean detectionTimedOut = false;
  
  boolean portReady() {
    return !spectruinoDetectionInProgress && !portInitializationInProgress;
  }
    
  void startPortDetection() {   
    detectionTimedOut = false;
    spectruinoDetectionInProgress = true;
    if (_DBG) {
      println("Available ports:");
      println(ports);
    }
    portInitializationInProgress = true;
    for (int i=0; i<ports.length; i++) {  
  //  int i=1;
      println("Opening " + ports[i]);
      try {      
        serials[i] = new Serial(spectruino05.this, ports[i], bitrate);
      } catch (Exception e) {
        serials[i] = null;
        println("Problem opening port " + ports[i] + ". Probably in use...");
        e.printStackTrace();
      }
  //    serials[i].buffer(3);  
      serials[i].bufferUntil(_c);  
  //    int j=0;
  //    while (serials[i].available()>0 && j<3) {
  //        println("read");
  //        inBuffer[j] = serials[i].readChar();
  //        j++;
  //    }
  //    println("Read");
  //    println(inBuffer); 
  //    serials[i].stop();

     }
     timer.start();
     portInitializationInProgress = false;
  }
  
  Serial checkPortDetection(Serial p) {
    println("checkPortDetection");
    if (portInitializationInProgress || detectionTimedOut()) {
      return null;
    }
    if (spectruinoDetectionInProgress) {
      byte[] portBytes = p.readBytes();
      if (!spectruino05.this.isHeaderPresent(portBytes, portBytes.length)) {
        return null;
      }
        // close other ports
      for (int i=0; i<serials.length; i++) {
          if (serials[i]!=p) {
            if (serials[i]!=null) {
              serials[i].stop();
            }
          } else {
            // found spectruino on port
            println("Spectruino on " + ports[i] + " (#" + i + ")");
            spectruinoDetectionInProgress = false;
          }
      }
      return p;
    } else {
      return null;
    }  
  }
  
  boolean detectionTimedOut() {
    if (!detectionTimedOut && spectruinoDetectionInProgress && timer.isFinished()) {
      for (int i=0; i<serials.length; i++) {
        if (serials[i]!=null) {
          serials[i].stop();
        }
      }
      detectionTimedOut = true;
      println("timer timed out");
    }
    return detectionTimedOut;
  }
}

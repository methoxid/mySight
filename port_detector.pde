import processing.serial.*;

class PortDetector  {
  
  int detectionInterval = 3 * 1000;  // N seconds
  Timer timer = new Timer(detectionInterval);
  String[] ports = new String[0];
  Serial[] serials = new Serial[ports.length];

  boolean portInitializationInProgress = false;
  boolean spectruinoDetectionInProgress = false;
  boolean detectionTimedOut = false;
  boolean mockPort = false;
  
  boolean portReady() {
    return mockPort || (!spectruinoDetectionInProgress && !portInitializationInProgress);
  }
  
  void init() {
      ports = Serial.list();
      serials = new Serial[ports.length];
      mockPort = false;
  }
    
  void startPortDetection(PApplet parent) {
    String[] portFound;                  // null if spectruino serial port not found (true if port was found)
    init();
    detectionTimedOut = false;
    spectruinoDetectionInProgress = true;

    println("Available ports:");
    println(ports);
    
    portInitializationInProgress = true;
    for (int i=0; i<ports.length; i++) {  
      println("Opening " + ports[i]);
      portFound = match(ports[i].toLowerCase(), "usb|com\\d*$"); //[uUcC][sSoO][bBmM]
      if (portFound!=null) {
        try {      
          serials[i] = new Serial(parent, ports[i], bitrate);
         //        serials[i] = new Serial(spectruino05.this, ports[i], bitrate); 
        } catch (Exception e) {
          serials[i] = null;
          println("Problem opening port " + ports[i] + ". Probably in use...");
          e.printStackTrace();
          continue;
        }

        serials[i].bufferUntil(_c);        
      }// End if portFound
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
////      if (!spectruino05.this.isHeaderPresent(portBytes, portBytes.length)) {
      if (!isHeaderPresent(portBytes, portBytes.length)) {  
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

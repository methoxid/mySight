import processing.serial.*;

class PortDetector  {
  
  int detectionInterval = 3 * 1000;  // N seconds
  Timer timer = new Timer(detectionInterval);
  String[] ports = new String[0];
  Serial[] serials = new Serial[ports.length];
  boolean deviceConnected = false;
  boolean portInitializationInProgress = false;
  boolean spectruinoDetectionInProgress = false;
  boolean detectionTimedOut = false;
  boolean mockPort = false;  // is simulation mode running?
  
  boolean portReady() {
    // is the physical port connected to spectruino?
    return (deviceConnected && !spectruinoDetectionInProgress && !portInitializationInProgress); // meaning application just started, or application has detected spectruino
  }
  
  void init() {
      ports = Serial.list();
      serials = new Serial[ports.length];
      mockPort = false;
      deviceConnected = false;
  }
    
  void startPortDetection(PApplet parent) {
    String[] portFound;                  // null if spectruino serial port not found (true if port was found)
    String[] portIsSpecial;              // we do not want special serial ports, otherwise errors when opening
    init();
    detectionTimedOut = false;
    spectruinoDetectionInProgress = true;

    println("Available ports:");
    println(ports);
    
    portInitializationInProgress = true;
    for (int i=0; i<ports.length; i++) {  
      println("Probing: " + ports[i]);
      portFound = match(ports[i].toLowerCase(), "usb|com\\d*$"); //[uUcC][sSoO][bBmM]
      portIsSpecial = match(ports[i].toLowerCase(), "cu.");
      //portFound = match(portFound, "!!!!!!!!!!!not cu.Bluetooth  alebo cu."); //[uUcC][sSoO][bBmM]      
      if (portFound!=null && portIsSpecial==null) {
        try {
          serials[i] = new Serial(parent, ports[i], bitrate);
        } catch (Exception e) {
          serials[i] = null;
          println("Problem probing port " + ports[i] + ".");
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
    println("Checking ports...");
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
            //if (_DBG) {
              println("Spectruino on port Nr. ["+i+"] "+ ports[i] );
              printMainText("\nSpectruino connected on port "+ports[i]);
            //}
            spectruinoDetectionInProgress = false;
          }
      }
      deviceConnected = true;      
      return p;
    } else {
      deviceConnected = false;
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

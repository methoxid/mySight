/** 
 * mySight - Spectruino Analyzer
 *  
 * by Andrej Mosat & Michal Kostic
 * zurich@myspectral.com 
 * http://myspectral.com
 * 
 *
 * This software is Licensed as follows:
 * 
 * Spectruino Spectrophotometer by Andrej Mosat is licensed under 
 * a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 * http://creativecommons.org/licenses/by-nc-sa/3.0/
 * additionally,
 * THE Spectruino Analyzer SOFTWARE IS PROVIDED TO YOU "AS IS," AND WE MAKE NO EXPRESS OR IMPLIED WARRANTIES WHATSOEVER WITH RESPECT TO ITS FUNCTIONALITY, OPERABILITY, OR USE, INCLUDING, WITHOUT LIMITATION, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR INFRINGEMENT. WE EXPRESSLY DISCLAIM ANY LIABILITY WHATSOEVER FOR ANY DIRECT, INDIRECT, CONSEQUENTIAL, INCIDENTAL OR SPECIAL DAMAGES, INCLUDING, WITHOUT LIMITATION, LOST REVENUES, LOST PROFITS, LOSSES RESULTING FROM BUSINESS INTERRUPTION OR LOSS OF DATA, REGARDLESS OF THE FORM OF ACTION OR LEGAL THEORY UNDER WHICH THE LIABILITY MAY BE ASSERTED, EVEN IF ADVISED OF THE POSSIBILITY OR LIKELIHOOD OF SUCH DAMAGES.
 * By running this software, you agree to the specified terms.
 * Based on a work at myspectral.com.
 * Permissions beyond the scope of this license may be available at http://myspectral.com .  
 * 
 * 
 *
 * Spectruino - myspectral.com UV/VIS spectrometer measures light spectrum.
 * This program receives the data over USB -> virtual serial port and displays the data in a graph.
 * First, connect Spectruino through your USB port. Run the program.
 * First available serial port will be selected as input.
 * 
 * 07/2012
 * v0.7
 * 
 *
 *
 */

/**
 * TODO/Ideas:
 - set and display Exposure Time 
 - display "Underexposed" "Overexposed"
 - detect Peaks
 - save spectrum as PDF, CSV
 - save a movie
 - measure dark level
 - dark level subtraction ON/OFF switch & display
 **/

import processing.serial.*;

boolean _DBG = true;                 // debug yes no 
int _ver=1;                          // Version number as int 
String _version="beta";          // Version description


//// Coordinates
int _dx=65;                          // delta X offset for drawing data
int _dy=65;                          // delta Y offset for drawing data
int _xsize=1026;                     // length of the image //int _xsize=1001;                   // length of the image 
int _ysize=256*2;                    // height of the image
int xpos, ypos;		             // Starting position of the ball
int _gain_y = 2;                     // Gain factor for displaying the data on y-axis
int _gain_x = 2;                     // Gain factor for x-axis
int _reverse_x = -1;                 // reverse x axis, sensor sends red --> blue color order (1 = normal, -1 = reversed)
int _reverse_y = -1;                 // reverse y axis, sensor sends high (255) values as darkness, low values as light (1 = normal, -1 = reversed)

//// Drawing, Shapes and Colors
int bgcolor;			     // Background color
int fgcolor;			     // Fill color
float _thck=2.0;                     // line thickness for axes 
PFont fontA;
//TODO: Add graphical myspectral icon //PGraphics icon;

Spectrum spectrum1;                  // global var
//int PXSIZE = 1001;                 // number of pixels to read from sensor
int PXSIZE = 501;                    // number of pixels to read from sensor
int PXDATALENGTH = 510;              // size of string received from sensor
int PXTOT = 2050;

//// Serial Port Communication
int bitrate = 115200;                // bitrate of Serial port in Baud
String portName;                     // serial COM port name
byte [] serialPixelBuffer = new byte[PXDATALENGTH]; // serial pixel data array as a Bytes, PX1, PX2, ....., PX501, HEADER
byte[] incomingDataBuffer = new byte[PXDATALENGTH]; 
int incomingDataLength=0;            // size of data read so far from input
int[] serialInArray = new int[PXTOT];// Where we'll put what we receive
int serialCount = 0;                 // A count of how many bytes we receive
Serial myPort;                       // The serial port       
String[] portFound;                  // null if spectruino serial port not found (true if port was found)
//// Header of Bytes from Serial 
int HEADER_SIZE = 9;                  // number of bytes in header +-1
String _cdelim = "yC";               // String delimiter from Microcontroller
int _c = int('C');                   // the delimiter character, e.g. "C" denoting end of serial pixel data array, PX1, PX2, ....., PX501, HEADER, where HEADER ends with _c 
PortDetector portDetector = new PortDetector();;   // Detecting the serial port on which Spectruino resides

//// General variables 
//int ccc=0; // counter
boolean _starting = true;   // if the application is starting 
//// Application states for debugging purposes and program flow

int APP_STATE_FIRST_RUN = 0;             // 1 - detecting spectruino
int APP_STATE_STARTED = 1; 
int APP_STATE_DETECTING = 1;
int APP_STATE_READY = 2;                 // 2 - spectruino detected  
int APP_STATE_MEASURE = 3;               // 3 - measurement in progress 
int APP_STATE_DETECTION_TIMED_OUT = -10; // 10 - spectruino detection timed out
int APP_STATE_MOCK_PORT = 4;
int appState = APP_STATE_FIRST_RUN;      // 0 - just started

//// Calibration data ////
// calibration works with y=a*x+b linear regression x = pixel, y=wavelength, a=slope [nm/px] b=intercept [nm]
float calibrationA=1.0;  // calibration coefficient, slope
float calibrationB=400.0; // calibration coefficient, intercept 
boolean calibrationFileFoundp=false; // calibration file found?


///////////////////////////// Initialize the device /////////////////////////////////
void prepareStage() {
  //size(1051, 562, P3D);  // Stage size
  size(1144, 642, P3D);  // Stage size, unfortunately, processing only allows constants here //size(_xsize+2*_dx, _ysize+2*_dy, P3D);  // Stage size
  stroke(4);
  // smooth(); // do not turn on, characters look bad with smooting
  background(bgcolor);
  frame.setTitle("mySight - myspectral.com Spectruino Analyzer v"+str(_ver));
  // Load the font. For vector fonts, use the createFont() function. 
  fontA = loadFont("Dosis-Regular-32.vlw");
  // Set the font and its size (in units of pixels)
  textFont(fontA, 32);
  println("Starting..."); 
}


void detectSpectruino() {
    appState = APP_STATE_DETECTING;
    portDetector.startPortDetection(this);
    clearScreen();
    printMainText("Detecting Spectruino...");
}

void startMockPort() {
  //// Setting a virtual Serial port for Simulation mode when Spectruino is not present
  appState = APP_STATE_MOCK_PORT;  
  portDetector.mockPort = true;
}

void setup() {
  prepareStage();
  clearScreen();
  printMainText("This is mySight for Spectruino beta.\nPress:\n[1] Start simulation [2] Detect spectruino\n[h] for help");
  // Load calibration file, if any 
  loadCalibrationFile();
}  


//////////////////////////// DRAW FUNCTION LOOP ////////////////////////////////////////////////////
void draw() {

  /////////////// Do following when program is first started ///////////////
  if (appState == APP_STATE_FIRST_RUN) {
 // if (_starting) {
    delay(500);
    axes();
    axes_labels();
    _starting=false;
    appState+=1;
  } //end if starting

  //// If Spectruino not present on serial port X
  if (!portDetector.portReady()) {
    if (portDetector.detectionTimedOut()) {
      appState = APP_STATE_DETECTION_TIMED_OUT;
      clearScreen();
      printMainText("Spectruino not detected\n[1] Start simulation [2] Detect again");
    }
    return;
  }
    
  ////if (_DBG) println("appState:" + appState);
  if (appState==APP_STATE_MOCK_PORT) {
      fillMockData(serialPixelBuffer);
      incomingDataLength = PXDATALENGTH;
  }

  ///////////////// Draw images when correct pixel data array received -- See EVENTS for Serial Port how to handle this ///////////////////
  if  (incomingDataLength == PXDATALENGTH) { //// Serial data of correct length has been received, construct the spectrum !!!  
    spectrum1 = new Spectrum(PXDATALENGTH-HEADER_SIZE, serialPixelBuffer);  // PXDATALENGTH-9 = 501           
  
    if (_DBG) {
      //printDataDigest(serialPixelBuffer);
      spectrum1._print();  //// Print the spectrum to command line output
    }

    stroke(255, 128, 0);
    spectrum1.plot();    //// Plot the received spectrum.
    axes();              //// (re)Plot axes
    //spectra.add();     //// TODO: save more spectra over a period of time into a stack buffer

    //// Draw a transparent rectangle over the renewable graph area, this ensures the effect of "diminishing over time"
    noStroke();
    fill(0, 20); //transparency
    rect(_dx+_thck,_dy,width,height-2*_dy);  
    incomingDataLength = 0;
  }
} // END Draw()



///////////////////////////////// EVENTS ///////////////////////////////////////////////

void processCompleteBuffer() {
    if (isHeaderPresent(incomingDataBuffer, PXDATALENGTH)) {
      System.arraycopy(incomingDataBuffer, 0, serialPixelBuffer, 0, incomingDataLength);
    } else if (_DBG) print(" >>ERR: isHeaderPresent:NO ");
}


//////////////////////////////// Serial Data received with a termination character _c ////////////////////////
void serialEvent(Serial p) {
  if (portDetector.spectruinoDetectionInProgress) {   
    if (portDetector.checkPortDetection(p)!=null) {
      myPort = p;
    } else if (portDetector.detectionTimedOut()) {
      // TODO: 
      println("No spectruino found");
    }
    return;
  }
  
  byte[] portBytes = myPort.readBytes();
  printDataDigest(portBytes);
  int currDataLength = portBytes.length;
  
  printDataDigest(portBytes);

  // XXX: check why occasionally crashing here - probably when spectruino is unplugged
   if (isHeaderPresent(portBytes, currDataLength)) {
     if(incomingDataLength+currDataLength==PXDATALENGTH) {
       // got complete measurement
        System.arraycopy(portBytes, 0, incomingDataBuffer, incomingDataLength, currDataLength);       
        incomingDataLength+=currDataLength;
        // process incomingDataBuffer
        processCompleteBuffer();
        return;       
     } else {
       // throw away everything
       incomingDataLength = 0;
       return;
     }
   } else {
     // header not present
     if (incomingDataLength+currDataLength<=PXDATALENGTH-HEADER_SIZE) {
        // paste into the buffer
        System.arraycopy(portBytes, 0, incomingDataBuffer, incomingDataLength, currDataLength);       
        incomingDataLength+=currDataLength;
        return;
     } else {
       // throw away
       incomingDataLength = 0;
       return;
     }
   }
}


void trashSerialEvent(Serial p) {
// everything after this, goes to trash in the future
    
  //// Serial Event is called when delimiter character _c is encountered.
  //  String tmpstring = (myPort.readString()); // 
  byte[] portBytes = myPort.readBytes();
  //  int strlen = tmpstring.length(); // length of the received string 
  int strlen = portBytes.length;
  print(" "+strlen);
  if ((strlen > 0) && (strlen <= PXDATALENGTH)) {
     // we got some data
    //// might be incomplete reading received, either _c character was encountered too early (can happen) or the reception begun too late
    //inString = inString + tmpstring;
    if (strlen==PXDATALENGTH) {
        // we got complete measuring => just throw away so far accumulated data and replace them with current measuring
        incomingDataLength=0;
    }
    System.arraycopy(portBytes, 0, incomingDataBuffer, incomingDataLength, strlen);
    incomingDataLength += strlen;
  } else if (strlen > PXDATALENGTH) {
    // more bytes than expected in this batch
    if ( (strlen>PXDATALENGTH+15) && (strlen<PXDATALENGTH+21) ) {
      //// more characters received than neccessary, user probably set new Exposure time in the middle of transmission
      //// Do nothing (data might be rescued, though, call Lancelot!)
    } 
    else if (_DBG) {
      //// more characters received than neccessary, error in serial data transmission occured
      println(">>ERR: serial stream pixel array too long. "+strlen);
    }   
    // inString="";
    incomingDataLength = 0;
  } else {
    //// unknown error occured => do nothing
    if (_DBG) println(">>ERR: serial stream pixel array ELSE. "+strlen);     
  }
  
  if (incomingDataLength == PXDATALENGTH) {
    //// complete serial port data reading received 
    //// PX1, PX2, PX3, .... PX501, HEADER, where HEADER = 
    //// sequence of "Ax low(PXSIZE) high(PXSIZE) B low(PXSIZE) high(PXSIZE) yC" is being sent
    //// and PXSIZE = 501 in Hexadecimal encoding LOW and HIGH byte
    ////delimiterFoundp = match(tmpstring, "[A][x]\?\?[B]\?\?yC");  //if (delimiterFoundp != null) {

    if (isHeaderPresent(incomingDataBuffer, PXDATALENGTH)) {
      System.arraycopy(incomingDataBuffer, 0, serialPixelBuffer, 0, incomingDataLength);
    } else if (_DBG) {
      //// Error, header not present
      print(" >>ERR: isHeaderPresent:NO ");
    }
  } 
}



boolean isHeaderPresent(byte[] arr, int headerEndIndex) {
  //// true if HEADER Bytes are present in the Serial Data Stream from Spectruino
  if (headerEndIndex-HEADER_SIZE<0) {
    return false;
  }

  short PXsize1 = bytes2short( Arrays.copyOfRange(arr, headerEndIndex-4, headerEndIndex-2), 0);  
  short PXsize2 = bytes2short( Arrays.copyOfRange(arr, headerEndIndex-7, headerEndIndex-5), 0);
//  short PXsize1 = bytes2short( Arrays.copyOfRange(portBytes, PXDATALENGTH-4, PXDATALENGTH-2), 0);
//  short PXsize2 = bytes2short( Arrays.copyOfRange(portBytes, PXDATALENGTH-7, PXDATALENGTH-5), 0);
//  print(" >>ERR: PXsize1 != PXsize2 "+PXsize1+" "+PXsize2);
  // XXX: check header properly!!! - including delimiting characters
  byte beforeLastHeaderVal = 121;
  return PXsize1==PXsize2 && arr[headerEndIndex-2]==beforeLastHeaderVal;
}

void mousePressed() {
  saveFrame("snapshots/####spectrum.png");
  background(0, 0, 0);
  axes();
  axes_labels();
  //       noStroke();
} // END mousepressed



void keyReleased() {
  if (appState==APP_STATE_DETECTION_TIMED_OUT || appState==APP_STATE_STARTED || appState==APP_STATE_FIRST_RUN) {
    handleKeySpectruinoNotDetected();
    return;
  }
  if (  appState == APP_STATE_MOCK_PORT ) {
    handleKeyRunning();
    return;
  }
  handleKeyRunning();
  handleKeySetExposure();  
} ////  END void keyReleased() {

///////////// Key Commands when Application is starting
void handleKeySpectruinoNotDetected() {
  switch(key) {
    case '1':
      println("start simulation serial mock port");
      startMockPort();
      break;
    case '2':
      println("detect spetruino again");
      detectSpectruino();
      break;
  }
} //END handleKeySpectruinoNotDetected

void handleKeyRunning() {
  switch (key) {
    case 'h':
    displayHelp();
    break;
  case ' ': //Space pressed 
    //// fixed wavelengths, 430 nm 453 nm 642 nm and 662 nm
    int w1=430, w2=453, w3=642, w4=662;
    ////println(spectrum1.getValueAtPixel(100));
    println(w1+" nm: "+spectrum1.getValueAtWavelength(w1));
    println(w2+" nm: "+spectrum1.getValueAtWavelength(w2));
    println(w3+" nm: "+spectrum1.getValueAtWavelength(w3));
    println(w4+" nm: "+spectrum1.getValueAtWavelength(w4));
    textSize(24);
    fill(255);
    text("Light intensity values: \n"+
      w1+" nm: "+spectrum1.getValueAtWavelength(w1)+", \n"+
      w2+" nm: "+spectrum1.getValueAtWavelength(w2)+", \n"+
      w3+" nm: "+spectrum1.getValueAtWavelength(w3)+", \n"+        
      w4+" nm: "+spectrum1.getValueAtWavelength(w4)+" "
      , width/4, height/2);                    
    break;
  } //   
} //End handleKeyRunning 
void handleKeySetExposure () {
    //// If numeric keys 1,2 ... 9,0 pressed,
  //// Send command "set exposure time(N)" to the serial port
  //// from ca. 0.4 s to 10 seconds, adjust for your application or think of other ways of setting exposure time
  //// for instance a slider might be a good choice.
  switch (key) {
  case '1':
    setExposureTime(1);
    break;
  case '2':
    setExposureTime(2);
    break;      
  case '3':
    setExposureTime(4);
    break;
  case '4':
    setExposureTime(6);
    break;
  case '5':
    setExposureTime(8);
    break;
  case '6':
    setExposureTime(10);
    break;
  case '7':
    setExposureTime(12);
    break;
  case '8':
    setExposureTime(16);
    break;
  case '9':
    setExposureTime(18);
    break;
  case '0':
    setExposureTime(20);
    break;        
  }
}





///////////////////////////////// HELPING CLASSES & Functions  /////////////////////////////////////// 

///////////////////////////////// Draw Axes on graph /////////////////////////////////////////////////
void axes() { 
  int x_every = 20*_gain_x;
  int y_every=40 ;
  int x_size_txt=20;
  int y_size_txt=20;
  fill(255);

  stroke(255, 255, 255);
  //// draw x-axis
  line(_dx-5, height-_dy, _dx+_xsize, height-_dy);
  //// draw y-axis
  line(_dx, height-_dy+5, _dx, height-(_dy+_ysize));
  //// draw x-ticks
  for (int i=0; i<(_xsize); i=i+x_every) {
    line(_dx+i, height-_dy+5, _dx+i, height-_dy);
  }

  // draw y-ticks
  for (int i=0; i<(height-2*_dy); i=i+y_every) {
    line(_dx-5, height-_dy-i, _dx, height-_dy-i);
  }
} // END axes()


void axes_labels() { 
  int x_every = 20*_gain_x;
  int y_every=40 ;
  int x_size_txt=20;
  int y_size_txt=20;
  fill(255);

  //// draw x-axis labels
  textSize(x_size_txt);
  textAlign(CENTER);
  //// Calibration file found? If yes, draw wavelength labels.
  if (calibrationFileFoundp) {
    for (int i=0; i<(_xsize); i=i+2*x_every) {
      text( int((i/_gain_x)*calibrationA+calibrationB), _dx+i, height-_dy+1.1*x_size_txt);
    }
    text("Wavelength [nm]",width/2, height-_dy+2.2*x_size_txt);
  }
  else {
    for (int i=0; i<(_xsize); i=i+2*x_every) {
      text(i/_gain_x, _dx+i, height-_dy+1.1*x_size_txt);
    }
    text("Pixel [#]",width/2, height-_dy+2.2*x_size_txt);
  }

  //// draw y-axis labels
  textSize(y_size_txt);
  textAlign(RIGHT);
  for (int i=0; i<(height-2*_dy); i=i+y_every) {
    text(i/_gain_y, _dx-5, height-_dy-i);
  }
  textAlign(CENTER);
  translate(0, height/2);      
  rotate(6*PI/4);
  text("Intensity [-]", 0, _dy-2.2*y_size_txt);// (height-_dy)/2);
  translate(width, height);
  rotate(0);


  textAlign(LEFT);
} // END axes_labels()


void displayHelp() {
  ////Send command to the serial port exposure time, press numeric keys 1,2 ... 9,0 from 0.4 s to 10 seconds  
  fill(244);
  textSize(24);
  text("Help. \n"+
    "[0][1][2]...[9]: Set exposure time. \n"+
    "[mouse click]: Save graph. \n"+
    "[space]: Get light intensity values at given wavelengths. \n"
    , width/4, height/2+26+26+26);    
  println("Help.");
} // END displayHelp()


void clearScreen() {
    noStroke();
//    fill(0, 20); //transparency
    fill(0);
    rect(_dx+_thck,_dy,width,height-2*_dy);  
}

void printMainText(String txt) {
  //fill(160);
  //textSize(18);
  fill(244);
//  textSize(24);
  text(txt, width/4, height/2);
}



///////////////////////////////// Spectrum Class  /////////////////////////////////////// 
class Spectrum {
  int len;
  int[] data;
  private int black=-1;

  Spectrum (int leng, byte[] buffer) {  
    len = leng;
    data = new int[len];    // measurement 
    for (int i=0; i<len; i++) {
      data[i]=int(buffer[i]);
    }
    if (len>0) {
      adjustNormalize();
    }
  } // End Spectrum constructor

  void adjustNormalize() {
    // subtract black level from data, which is stored at position 0
    //    black=255-data[0]; // 8-bit resolution
//    if (_DBG) {
//       println("data before adjust");
//       printDataDigest(data);
//    }

    if (_reverse_y>0) {
      black=255-max(data); // 8-bit resolution // this is the "real" black level
    } 
    else {
      black=max(data); // 8-bit resolution // this is the "real" black level
    }  
    if (black < 0 ) { 
      black=0;
    } // this needs to be checked thoroughly
 ////   if (_DBG) println("black:" + black);
    
    for (int i=0; i<len; i++) {
      data[i]=_reverse_y*(data[i]-black);
    }
    if (_reverse_x<0) {
      int[] tmp = new int[len];    // measurement
      tmp = data.clone();
      //      for (int i=len; i>0; i--) {
      //        data[i]=_reverse_y*(data[i]-black);
      //      } 
      arrayreverse(data);
    }
//    if (_DBG) {
//      println("adjustedData");
//      printDataDigest(data);
//    }
  } // End Spectrum.adjustNormalize

  public int getValueAtPixel(int pixel) {
    //// return a light intensity value at pixel # (pixel is the i-th index of current spectrum measurement)
    int value=-1;
    if ( (pixel<len) && (pixel>0) ) {
      value=data[pixel];
    }
    return value;
  } // End Spectrum.getValueAtPixel

  public int getValueAtWavelength(int wavelength) {
    //// first, convert wavelength to pixel #
    //// then call getValueAtPixel(int pixel)
    //// return a light intensity value at pixel # (pixel is the i-th index of current spectrum measurement)
    int value=-1;
    if ( (wavelength>=calibrationB) && (wavelength<(calibrationA*len+ calibrationB)) ) {
      //// y(wavelength)=a*x(pixel#)+b
      value = getValueAtPixel(int( (wavelength-calibrationB)/calibrationA ) ) ;
    }
    return value;
  }  // End Spectrum.getValueAtWavelength

  void plot() {
    int _hue = len+1; // number of hue shades 
    int _hueblue = floor(0.2*_hue); // blue color starts at about 20% of the H
    _hue += _hueblue; // adjust for the blue color start in the HSB 

    colorMode(HSB, _hue, 100, 100);
    for (int i=2; i<len; i++) {
      //       point(_dx+i, height-_dy-(_gain_y*data[i]));
      stroke(_hue-(i+_hueblue),100,100);
      line(_dx+(_gain_x*i)-1, height-_dy-(_gain_y*(data[i-1])), _dx+_gain_x*i, height-_dy-(_gain_y*(data[i])));
      //      line(_dx+i-1, height-_dy-(data[i-1]), _dx+i, height-_dy-(data[i]));
    }
    colorMode(RGB, 255);
  } // End Spectrum.plot()

  void _print() {
    print("#Sp["+len+"]: [");
    if (len>3) {
      print(data[0]+" "+data[1]+" "+data[2]);
      if (len>7) {
        print(" ... "+data[len-3]+" "+data[len-2]+" "+data[len-1]);
      }
    }
    println("]");
  } // End Spectrum.print()
} /////////////////// END OF SPECTRUM CLASS ///////////////////////////////////////


/////////////////// Generic functions ///////////////////////////////////////////
public static short bytes2short(byte[] data, int offset) {
  return (short) (((data[offset+1] << 8)) | ((data[offset + 0] & 0xff)));
}


void arrayreverse(int[] array) {
  if (array == null) {
    return;
  }
  int i = 0;
  int j = array.length - 1;
  int tmp;
  while (j > i) {
    tmp = array[j];
    array[j] = array[i];
    array[i] = tmp;
    j--;
    i++;
  }
}



/////////////////// LOAD calibration file /////////////////////////////////////// 
void loadCalibrationFile() {

  String CFGfilePath="CFG-spectruino-calibration.txt";
  File file = new File(sketchPath(CFGfilePath));
  if (file.exists())
  {
    String lines[] = loadStrings(CFGfilePath);
    String [][] csv;
    int csvWidth=0;

    //calculate max width of csv file
    for (int i=0; i < lines.length; i++) {
      String [] chars=split(lines[i],',');
      if (chars.length>csvWidth) {
        csvWidth=chars.length;
      }
    }

    //create csv array based on # of rows and columns in csv file
    csv = new String [lines.length][csvWidth];

    //parse values into 2d array
    for (int i=0; i < lines.length; i++) {
      String [] temp = new String [lines.length];
      temp= split(lines[i], ',');
      for (int j=0; j < temp.length; j++) {
        csv[i][j]=temp[j];
      }
    }
    //test
    println("Calibration file found: ");
    println(" "+csv[0][0]);
    println("Slope: "+csv[1][0]);
    println("Intercept: "+csv[2][0]);

    //      //// Calibration data ////
    //      // calibration works with y=a*x+b linear regression x = pixel, y=wavelength, a=slope [nm/px] b=intercept [nm]
    //      float calibrationA=1.0;  // calibration coefficient, slope
    //      float calibrationB=400.0; // calibration coefficient, intercept 
    //      boolean calibrationFileFoundp=false; // calibration file found?
    calibrationFileFoundp=true;
  } 
  else {
    println("Calibration file not found." + CFGfilePath);
  }
}/////////////////// END of calibration file ///////////////////////////////////////




/////////////////////// SET EXPORSURE TIME ////////////////////////////////////////
void setExposureTime(int valueTime) {
  myPort.write('#');
  myPort.write(valueTime);
  myPort.write('#');
  myPort.write(valueTime);
  //    if ( _DBG ) {
  //      println("EXPosure time: "+valueTime+" ");      
  //    }
  println("EXPosure time: "+valueTime+" ");
}
/////////////////////// END SET EXPORSURE TIME ////////////////////////////////////////

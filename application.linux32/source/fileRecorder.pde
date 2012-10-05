// The FileRecorder writes/appends the interval data to the recorder tab delineated text file.
//
class FileRecorder {
  String _filePath;
  String[] _textLine = new String[4];

  void setFilePath(String theFName) {
    _filePath = theFName;
    println("File record name is " + _filePath);
  }

  void writeHeader(String customText) {
    _textLine[0] = "Spectruino Beta v1.0 mySight " + TAB + "Light intensity vs. Wavelength [nm] / Pixel count [#]" + TAB; //_textLine[0] + 
    _textLine[1] = "Timestamp: " + datetime();
    _textLine[2] = customText;
    ////@TODO: "Wavelength [nm] (to be implemented...) ,";
    _textLine[3] = "Pixel #," + TAB + "Light Intensity [a.u.],"+ TAB + "Wavelength [nm] (to be implemented...) ,";
    if (_filePath != null) {
      saveStrings(savePath(_filePath), _textLine);
      println("Wrote header to " + savePath(_filePath));
      println(_textLine[0]);
    }
  }

  //// Write data from measurement history into a file
  void writeData(Vector S) {
    PrintWriter pw = null;
    try {
      pw = new PrintWriter(new BufferedWriter(new FileWriter(savePath(_filePath), true))); // true means: "append"
      int[] data = (int[]) S.get(0);
      int[][] mx = new int[S.size()][data.length];

      for (int h=S.size()-1;h>=0; h--)
      { data = (int[]) S.get(h);
        mx[h]= data; //data = (int[]) S.get(h); 
      }
      
    for (int i = 0; i < data.length; i++) {
      pw.print(i);
      for (int j=0; j<S.size();j++){
        pw.print("," + TAB + mx[j][i]);
      }
      pw.print("\r\n");
    }   
    //dataLine = dataLine.replaceAll(" ","\t");
    }


    catch (IOException e) {
      // Report problem or handle it
      e.printStackTrace();
    }

    finally {
      if (pw != null) {
        pw.close();
      }
    }
  }
}


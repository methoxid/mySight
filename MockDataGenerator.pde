

void fillMockData(byte[] arr) {
    int PXSIZE = arr.length;
    for (int ii=0; ii<arr.length; ii++) {
      arr[ii] =  byte( 250*sin( ii*3.14/PXSIZE )*(-0.5+1/( spectruino05.this.random(200000)-100000))-30 - spectruino05.this.random(4));
 //     inBuffer[ii] =  byte(  int(  (1+1/random(100))*sin(ii*(3.14/PXSIZE))+random(4) ));
    }
    arr[arr.length-3] = 121;
    arr[arr.length-2] = 67;
  
}

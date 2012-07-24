
//// These functions generate data in simulation mode 

void fillMockData(byte[] arr) {
   //// This generates a sinus function with random noise  
    int PXSIZE = arr.length;
    for (int ii=0; ii<arr.length; ii++) {
      arr[ii] =  byte( 250*sin( ii*3.14/PXSIZE )*(-0.5+1/( this.random(200000)-100000))-30 - this.random(4)); 
    }
    arr[arr.length-3] = 121;
    arr[arr.length-2] = 67;
  
}

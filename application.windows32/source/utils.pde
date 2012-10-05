String mydate(int offset)
{
  Date d = new Date();
  long timestamp = d.getTime() + (86400000 * offset);
  String date = new java.text.SimpleDateFormat("yyyyMMdd").format(timestamp);
  return date;
}

String today()
{
  return mydate(0);
}

String mytime()
{  Date d = new Date();
  long timestamp = d.getTime();
  String date = new java.text.SimpleDateFormat("HHmmss").format(timestamp);
  return date;
}

String datetimefile()
{  Date d = new Date();
  long timestamp = d.getTime();
  String date = new java.text.SimpleDateFormat("yyyyMMddHHmmss").format(timestamp);
  return date;
}
String datetime()
{  Date d = new Date();
  long timestamp = d.getTime();
  String date = new java.text.SimpleDateFormat("yyyy/MM/dd HH:mm:ss").format(timestamp);
  return date;
}

void printDataDigest(byte[] arr) {
  int digestStartLength = 5;
  int digestEndLength = 5;  
  int digestStartEndIndex = min(arr.length, digestStartLength);
  int digestEndStartIndex = arr.length-(digestEndLength+HEADER_SIZE);
  StringBuilder sb = new StringBuilder();
  
  for (int i=0; i<digestStartEndIndex; i++) {
    sb.append(String.valueOf(arr[i]));
    sb.append(",");
  }
  if (digestEndStartIndex>=0 && digestEndStartIndex>digestStartEndIndex) {
    sb.append("..., ");
    for (int i=digestEndStartIndex; i<arr.length; i++) {
      sb.append(String.valueOf(arr[i]));
      sb.append(",");
    }
  }

  println(sb.toString());
}

void printDataDigest(int[] arr) {
  int digestStartLength = 5;
  int digestEndLength = 5;  
  int digestStartEndIndex = min(arr.length, digestStartLength);
  int digestEndStartIndex = arr.length-(digestEndLength+HEADER_SIZE);
  StringBuilder sb = new StringBuilder();
  
  for (int i=0; i<digestStartEndIndex; i++) {
    sb.append(String.valueOf(arr[i]));
    sb.append(",");
  }
  if (digestEndStartIndex>=0 && digestEndStartIndex>digestStartEndIndex) {
    sb.append("..., ");
    for (int i=digestEndStartIndex; i<arr.length; i++) {
      sb.append(String.valueOf(arr[i]));
      sb.append(",");
    }
  }

  println(sb.toString());
}


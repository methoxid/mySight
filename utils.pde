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


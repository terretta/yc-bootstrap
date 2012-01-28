function removeDoubleLine(obj) {
   var str = obj.value;
   while(str.indexOf("\r\n\r\n") >= 0) {
      str = str.replace(/\r\n\r\n/g, "\r\n")      
   }
   obj.value = str;
}

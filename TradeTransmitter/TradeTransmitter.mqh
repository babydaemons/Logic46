//+------------------------------------------------------------------+
//| HTTP GET function                                                |
//+------------------------------------------------------------------+
string Get(string uri) {
   char data[];
   char result[];
   string result_headers;
   int res = WebRequest("GET", uri, NULL, 1000, data, result, result_headers);
   if (res != 200) {
      MessageBox(StringFormat("ERROR: HTTP Response %d: %s", res, ErrorDescription()));
   }
   int size = ArraySize(result);
   uchar result_data[];
   ArrayResize(result_data, size);
   for (int i = 0; i < size; ++i) {
      result_data[i] = result[i];
   }
   string text = CharArrayToString(result_data);
   return text;
}

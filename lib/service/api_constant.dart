// import 'dart:convert';

class ApiConstant {
  static String baseApiURL = "https://www.naqshbandiindia.com/wp-json/wp/v2";
  static String pageEndPoint = '/pages?context=view&pageNum=1&perPage=10';
  static String bookEndPoint =
      '/media?context=view&media_type=application&mime_type=application/pdf';
  static String audioEndPoint = '/media?context=view&media_type=audio';

  // UmmahAPI configuration for Quran
  static String ummahApiBaseURL = "https://ummahapi.com/api";
  static String ummahApiKey = "umh_199d4d0eb019566bc7218ac5e9c855385edc366a";
}

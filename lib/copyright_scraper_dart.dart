import 'package:puppeteer/puppeteer.dart';

class Scraper {
  String year;
  int pages;
  late List<String> dateRange;
  late Browser _browser;
  late Page _page;
  String originLink = 'https://publicrecords.copyright.gov/';
  List<String> results = [];

  Scraper({
    required this.year,
    required this.pages,
  }) {
    dateRange = setDateRange(year = year);
  }

  List<String> setDateRange(String year) {
    if (year == '2024') {
      return ['2024-01-01', '2024-06-20'];
    }
    return ['$year-01-01', '$year-12-31'];
  }

  Future<void> setUpBrowser() async {
    _browser = await puppeteer.launch(headless: false);
    _page = await _browser.newPage();
    await _page.goto(originLink, wait: Until.domContentLoaded);
  }

  Future<void> getData() async {
    await setUpBrowser();
  }
}

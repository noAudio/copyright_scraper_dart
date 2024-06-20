import 'package:copyright_scraper_dart/copyright_scraper_dart.dart';

void main(List<String> arguments) async {
  Scraper scraper = Scraper(year: '2024', pages: 222);
  await scraper.getData();
}

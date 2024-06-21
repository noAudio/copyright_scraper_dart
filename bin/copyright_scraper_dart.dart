import 'dart:io';

import 'package:copyright_scraper_dart/copyright_info.dart';
import 'package:copyright_scraper_dart/copyright_scraper_dart.dart';

void main(List<String> arguments) async {
  String year = '2023';
  int pages = 287;
  String startDate = '2023-01-01';
  String endDate = '2023-06-30';
  // var dateRange = year == '2024'
  //     ? ['2024-01-01', '2024-06-20']
  //     : ['$year-01-01', '$year-12-31'];
  var total = <CopyRightInfo>[];
  for (int page = 1; page <= pages; page++) {
    Scraper scraper = Scraper(year: year, pages: pages);
    // if (page == 5) break;
    print('$page of $pages');
    await scraper.getData(
        'https://publicrecords.copyright.gov/advanced-search?page_number=$page&parent_query=%5B%7B%22operator_type%22:%22AND%22,%22column_name%22:%22all_copyright_numbers%22,%22type_of_query%22:%22starts_with%22,%22query%22:%22TXu%22%7D%5D&records_per_page=100&sort_order=%22asc%22&highlight=true&model=%22%22&date_field=%22registration_date_as_date%22&start_date=%22$startDate%2000:00:00%22&end_date=%22$endDate%2000:00:00%22');
    for (var result in scraper.results) {
      total.add(result);
    }
    // print(total.length);
  }
  File file = File('$year-p1-records.csv');
  for (var result in total) {
    file.writeAsStringSync(
      '"${result.registrationNumberAndDate}", "${result.applicationTitle}", "${result.copyrightClaimant}", "${result.rightsAndPermissions}", "${result.typeOfWork}"\n',
      mode: FileMode.append,
    );
  }
}

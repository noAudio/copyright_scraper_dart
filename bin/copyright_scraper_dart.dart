import 'dart:async';
import 'dart:io';

import 'package:excel/excel.dart';

import 'package:copyright_scraper_dart/copyright_info.dart';
import 'package:copyright_scraper_dart/copyright_scraper_dart.dart';

void main(List<String> arguments) async {
  var years = <String>[
    '1999',
    '1998',
    '1997',
    '1996',
    '1995',
    '1994',
    '1993',
    '1992',
    '1991',
    '1990',
  ];
  var totalPages = <List<int>>[
    [288, 229],
    [291, 259],
    [288, 273],
    [262, 259],
    [268, 253],
    [248, 252],
    [246, 248],
    [225, 230],
    [227, 235],
    [252, 272],
  ];

  for (int j = 0; j <= years.length; j++) {
    String year = years[j];
    for (var pages in totalPages[j]) {
      int index = totalPages[j].indexOf(pages);
      // String startDate = '$year-01-01';
      // String endDate = '$year-06-30';
      String startDate = index == 0 ? '$year-01-01' : '$year-07-01';
      String endDate = index == 0 ? '$year-06-30' : '$year-12-31';

      var total = <CopyRightInfo>[];
      for (int page = 1; page <= pages; page++) {
        Scraper scraper = Scraper(year: year, pages: pages);
        // if (page == 5) break;
        print('$year - $page of $pages (${pages - page} pages left)');
        try {
          await scraper
              .getData(
                  'https://publicrecords.copyright.gov/advanced-search?page_number=$page&parent_query=%5B%7B%22operator_type%22:%22AND%22,%22column_name%22:%22all_copyright_numbers%22,%22type_of_query%22:%22starts_with%22,%22query%22:%22TXu%22%7D%5D&records_per_page=100&sort_order=%22asc%22&highlight=true&model=%22%22&date_field=%22registration_date_as_date%22&start_date=%22$startDate%2000:00:00%22&end_date=%22$endDate%2000:00:00%22')
              .timeout(Duration(seconds: 60));
        } on TimeoutException catch (e) {
          print('$e. Rechecking page $page.');
          await scraper.closeBrowser();
          page = page - 1;
          continue;
        } catch (e) {
          print(e);
          if (scraper.isBrowserOpen()) {
            await scraper.closeBrowser();
          }
          page = page - 1;
          print('Repeating page ${page + 1}');
          continue;
        }

        for (var result in scraper.results) {
          total.add(result);
        }
        // print(total.length);
      }
      print('Structuring spreadsheet...');
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];
      int i = 1;

      for (var result in total) {
        sheet.appendRow([
          sheet.cell(CellIndex.indexByString('A$i')).value =
              TextCellValue(result.registrationNumberAndDate),
          sheet.cell(CellIndex.indexByString('B$i')).value =
              TextCellValue(result.applicationTitle),
          sheet.cell(CellIndex.indexByString('C$i')).value =
              TextCellValue(result.copyrightClaimant),
          sheet.cell(CellIndex.indexByString('D$i')).value =
              TextCellValue(result.rightsAndPermissions),
          sheet.cell(CellIndex.indexByString('E$i')).value =
              TextCellValue(result.typeOfWork)
        ]);
        i++;
      }

      print('Writing to file...');
      final excelFile = File(
          '$year-${endDate.contains('-06-30') ? 'p1' : 'p2'}-records.xlsx');
      var bytes = excel.encode() as List<int>;
      excelFile.writeAsBytesSync(bytes);
      print('Completed!');
    }
  }
}

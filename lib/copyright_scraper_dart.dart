import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:copyright_scraper_dart/copyright_info.dart';
import 'package:puppeteer/puppeteer.dart';

class Scraper {
  String year;
  int pages;
  late List<String> dateRange;
  Browser? _browser;
  late Page _page;
  late Completer<void> _completer;
  String originLink = 'https://publicrecords.copyright.gov/';
  List<CopyRightInfo> results = [];

  Scraper({
    required this.year,
    required this.pages,
  }) {
    dateRange = setDateRange(year = year);
    _completer = Completer<void>();
  }

  List<String> setDateRange(String year) {
    if (year == '2024') {
      return ['2024-01-01', '2024-06-20'];
    }
    return ['$year-01-01', '$year-12-31'];
  }

  Future<void> setUpBrowser() async {
    _browser = await puppeteer.launch(headless: true);
    _page = await _browser!.newPage();
  }

  bool isBrowserOpen() => _browser != null;

  Future<void> closeBrowser() async {
    await _browser!.close();
  }

  Future<void> getData(String link) async {
    await setUpBrowser();

    await _page.goto(link, wait: Until.domContentLoaded);
    sleep(Duration(seconds: Random().nextInt(6) + 3));
    var url = '';

    _page.onResponse.listen((response) async {
      url = response.url;
      if (url ==
          'https://api.publicrecords.copyright.gov/search_service_external/advance_search') {
        if (response.status == 200) {
          try {
            var payload = await response.json;
            print('Found data...');
            extractInfo(payload);
          } catch (e) {
            print(e);
          }
        }
      }
    });
    await _completer.future;
    await _browser!.close();
  }

  void extractInfo(dynamic payload) {
    print('Extracting data...');
    List<dynamic> data = payload['data'];
    for (var item in data) {
      String regNo = item['hit']['registration_number'];

      // Skip non TXu records
      if (regNo.substring(0, 3).toLowerCase() != 'txu') continue;

      String regNoAndDate =
          "${item['hit']['registration_number']} / ${item['hit']['representative_date']}";
      String applicationTitle = item['hit']['title_application_title'] != null
          ? item['hit']['title_application_title'][0]
          : item['hit']['title_concatenated'] != null
              ? item['hit']['title_concatenated']
              : 'TITLE MISSING';
      String copyrightClaimant = item['hit']['claimants_list'] != null
          ? "${item['hit']['claimants_list'][0]['claimant_full_name']}, ${item['hit']['claimants_list'][0]['claimant_dates'] != null ? item['hit']['claimants_list'][0]['claimant_dates'].split(' ')[0] : ''}. ${item['hit']['claimants_list'][0]['claimant_address']}"
          : 'n/a';
      String rightsPermissions =
          item['hit']['rights_and_permissions_statement'] != null
              ? item['hit']['rights_and_permissions_statement'].join(' ')
              : 'n/a';
      String typeWork = item['hit']['type_of_work'];

      results.add(
        CopyRightInfo(
          registrationNumberAndDate: regNoAndDate.replaceAll('"', ''),
          applicationTitle: applicationTitle.replaceAll('"', ''),
          copyrightClaimant: copyrightClaimant.replaceAll('"', ''),
          rightsAndPermissions: rightsPermissions.replaceAll('"', ''),
          typeOfWork: typeWork.replaceAll('"', ''),
        ),
      );
    }
    _completer.complete();
  }
}

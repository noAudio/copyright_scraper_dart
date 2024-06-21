import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:copyright_scraper_dart/copyright_info.dart';
import 'package:puppeteer/puppeteer.dart';

class Scraper {
  String year;
  int pages;
  late List<String> dateRange;
  late Browser _browser;
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
    _page = await _browser.newPage();
    // await _page.goto(originLink, wait: Until.domContentLoaded);
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
            extractInfo(payload);
          } catch (e) {
            print(e);
          }
        }
      }
    });
    // print(results[results.length - 1].applicationTitle);
    await _completer.future;
    await _browser.close();
  }

  void extractInfo(dynamic payload) {
    List<dynamic> data = payload['data'];
    int length = results.length;
    for (var item in data) {
      String regNoAndDate =
          "${item['hit']['registration_number']} / ${item['hit']['representative_date']}";
      String applicationTitle = item['hit']['title_application_title'][0];
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
          registrationNumberAndDate: regNoAndDate,
          applicationTitle: applicationTitle,
          copyrightClaimant: copyrightClaimant,
          rightsAndPermissions: rightsPermissions,
          typeOfWork: typeWork,
        ),
      );
    }
    if (results.length == length + data.length) {
      _completer.complete();
    }
    // print(results.length);
  }
}

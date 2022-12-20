import 'package:easy_localization/easy_localization.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/source_provider.dart';

class SteamMobile extends AppSource {
  SteamMobile() {
    host = 'store.steampowered.com';
    name = tr('steam');
    additionalSourceAppSpecificSettingFormItems = [
      [
        GeneratedFormItem('app',
            label: tr('app'), required: true, opts: apks.entries.toList())
      ]
    ];
  }

  final apks = {'steam': tr('steamMobile'), 'steam-chat-app': tr('steamChat')};

  @override
  String standardizeURL(String url) {
    return 'https://$host';
  }

  @override
  String? changeLogPageFromStandardUrl(String standardUrl) => null;

  @override
  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, String> additionalSettings,
  ) async {
    Response res = await get(Uri.parse('https://$host/mobile'));
    if (res.statusCode == 200) {
      var apkNamePrefix = additionalSettings['app'];
      if (apkNamePrefix == null) {
        throw NoReleasesError();
      }
      String apkInURLRegexPattern = '/$apkNamePrefix-[^/]+\\.apk\$';
      var links = parse(res.body)
          .querySelectorAll('a')
          .map((e) => e.attributes['href'] ?? '')
          .where((e) => RegExp('https://.*$apkInURLRegexPattern').hasMatch(e))
          .toList();

      if (links.isEmpty) {
        throw NoReleasesError();
      }
      var versionMatch = RegExp(apkInURLRegexPattern).firstMatch(links[0]);
      if (versionMatch == null) {
        throw NoVersionError();
      }
      var version = links[0].substring(
          versionMatch.start + apkNamePrefix.length + 2, versionMatch.end - 4);
      var apkUrls = [links[0]];
      return APKDetails(version, apkUrls, AppNames(name, apks[apkNamePrefix]!));
    } else {
      throw NoReleasesError();
    }
  }
}

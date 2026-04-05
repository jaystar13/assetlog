import 'package:app_links/app_links.dart';

class DeepLinkService {
  final AppLinks _appLinks;

  DeepLinkService({AppLinks? appLinks})
      : _appLinks = appLinks ?? AppLinks();

  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  Stream<Uri> get onLink => _appLinks.uriLinkStream;
}

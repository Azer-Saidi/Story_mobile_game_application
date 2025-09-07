import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StoryCacheManager extends CacheManager with ImageCacheManager {
  static const String _key = 'storyCache';
  static const Duration _maxAge = Duration(days: 30);

  static final StoryCacheManager _instance = StoryCacheManager._();
  factory StoryCacheManager() => _instance;
  StoryCacheManager._()
      : super(
          Config(
            _key,
            maxNrOfCacheObjects: 200,
            stalePeriod: _maxAge,
            repo: JsonCacheInfoRepository(databaseName: _key),
            fileService: HttpFileService(),
          ),
        );

  /// Optimised Cloudinary helper
  Future<File> getCloudinaryFile(
    String publicId, {
    int width = 600,
    String format = 'auto',
  }) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'demo';
    final url =
        'https://res.cloudinary.com/$cloudName/image/upload/c_fill,f_$format,q_auto,w_$width/$publicId';
    return getSingleFile(url, key: publicId);
  }

  Future<File> getFileFromUrl(String url, {String? key}) {
    // If key is not provided, the cache manager will derive one from the URL
    return getSingleFile(url, key: key);
  }
}

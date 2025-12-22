import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 이미지 확대 뷰어
///
/// 네트워크 이미지 또는 로컬 파일 이미지를 확대하여 볼 수 있는 갤러리 뷰어
class ImageViewer extends StatefulWidget {
  /// 네트워크 이미지 URL 리스트 (우선)
  final List<String>? imageUrls;

  /// 로컬 이미지 파일 리스트
  final List<File>? imageFiles;

  /// 초기 표시할 이미지 인덱스
  final int initialIndex;

  /// 네트워크 이미지 뷰어 생성
  const ImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  }) : imageFiles = null;

  /// 로컬 파일 이미지 뷰어 생성
  const ImageViewer.file({
    super.key,
    required this.imageFiles,
    this.initialIndex = 0,
  }) : imageUrls = null;

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _totalImages {
    if (widget.imageUrls != null) {
      return widget.imageUrls!.length;
    } else if (widget.imageFiles != null) {
      return widget.imageFiles!.length;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} / $_totalImages',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 이미지 갤러리
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: _getImageProvider(index),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: 'image_$index'),
              );
            },
            itemCount: _totalImages,
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
            pageController: _pageController,
            onPageChanged: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),

          // 인디케이터 (이미지 여러 개인 경우에만 표시)
          if (_totalImages > 1)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalImages,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 인덱스에 해당하는 ImageProvider 반환
  ImageProvider _getImageProvider(int index) {
    if (widget.imageUrls != null) {
      // 네트워크 이미지
      return CachedNetworkImageProvider(widget.imageUrls![index]);
    } else if (widget.imageFiles != null) {
      // 로컬 파일 이미지
      return FileImage(widget.imageFiles![index]);
    }
    throw Exception('No images provided');
  }
}

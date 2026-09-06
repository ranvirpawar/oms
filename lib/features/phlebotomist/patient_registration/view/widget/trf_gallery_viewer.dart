import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';


class TrfGalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const TrfGalleryViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<TrfGalleryViewer> createState() => _TrfGalleryViewerState();
}

class _TrfGalleryViewerState extends State<TrfGalleryViewer> {
  late int _currentIndex;
  late PageController _pageController;

  // Track rotation quarters (0 = 0°, 1 = 90°, 2 = 180°, 3 = 270°)
  late List<int> _rotations;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    // Initialize all images with 0 rotation
    _rotations = List.filled(widget.imageUrls.length, 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleRotation() {
    setState(() {
      // Increment by 1 quarter turn (90 degrees)
      _rotations[_currentIndex] = (_rotations[_currentIndex] + 1) % 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'TRF Image ${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined, color: Colors.white),
            onPressed: _handleRotation,
          ),
        ],
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        builder: (context, index) {
          return PhotoViewGalleryPageOptions.customChild(
            // Use a Unique Key based on rotation so PhotoView recalculates "fit"

            child: RotatedBox(
              quarterTurns: _rotations[index],
              child: Image.network(
                widget.imageUrls[index],
                fit: BoxFit.contain,
              ),
            ),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4,
            heroAttributes: PhotoViewHeroAttributes(tag: widget.imageUrls[index]),
          );
        },
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
      // --- Your Thumbnail Strip ---
      bottomNavigationBar: widget.imageUrls.length > 1
          ? Container(
        color: Colors.black,
        height: 72,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: widget.imageUrls.length,
          itemBuilder: (context, index) {
            final isSelected = index == _currentIndex;
            return GestureDetector(
              onTap: () => _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      )
          : null,
    );
  }
}
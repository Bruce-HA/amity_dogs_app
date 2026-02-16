import 'package:flutter/material.dart';

class PhotoViewerPage extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const PhotoViewerPage({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late PageController _controller;

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    currentIndex = widget.initialIndex;

    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "${currentIndex + 1} / ${widget.photos.length}",
          style: const TextStyle(color: Colors.white),
        ),
      ),

      body: PageView.builder(
        controller: _controller,

        itemCount: widget.photos.length,

        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        itemBuilder: (_, index) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,

            child: Center(
              child: Image.network(widget.photos[index], fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}

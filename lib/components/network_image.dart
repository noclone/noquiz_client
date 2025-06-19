import 'package:flutter/material.dart';

import '../utils/preferences.dart';

class NoQuizNetworkImage extends StatefulWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;

  const NoQuizNetworkImage({
    Key? key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  _NoQuizNetworkImageState createState() => _NoQuizNetworkImageState();
}

class _NoQuizNetworkImageState extends State<NoQuizNetworkImage> {
  String imageUrlPrefix = "";

  void setUrlPrefix() async {
    final serverIp = await getServerIpAddress();
    final urlPrefix = "http://$serverIp:8000";
    setState(() {
      imageUrlPrefix = urlPrefix;
    });
  }

  String getUrlFromPrefix(String url, String prefix){
    return url.startsWith("http") ? url : prefix + url;
  }

  @override
  void initState() {
    super.initState();
    setUrlPrefix();
  }

  @override
  Widget build(BuildContext context) {
    return imageUrlPrefix.isNotEmpty
        ? Image.network(
      getUrlFromPrefix(widget.imagePath, imageUrlPrefix),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
    )
        : const CircularProgressIndicator();
  }
}

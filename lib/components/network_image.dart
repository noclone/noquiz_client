import 'package:flutter/material.dart';
import 'package:noquiz_client/utils/preferences.dart';


class NQNetworkImage extends StatefulWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;

  const NQNetworkImage({
    Key? key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  _NQNetworkImageState createState() => _NQNetworkImageState();
}

class _NQNetworkImageState extends State<NQNetworkImage> {
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

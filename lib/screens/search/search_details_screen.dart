import 'package:flutter/material.dart';
import '../../app/constants.dart';
import '../../app/mixins/cache.dart';
import '../../app/models/passage.dart';

class SearchDetailsScreen extends StatefulWidget {
  final Passage passage;
  final int headIndex;

  const SearchDetailsScreen({
    Key? key,
    required this.passage,
    required this.headIndex,
  }) : super(key: key);

  @override
  State<SearchDetailsScreen> createState() => _SearchDetailsScreenState();
}

class _SearchDetailsScreenState extends State<SearchDetailsScreen> with AppCache {
  double _custTextSize = Constants.defaultTextSize;
  double _custTitleSize = Constants.defaultTitleSize;

  @override
  void initState() {
    super.initState();
    // Load the saved text diff from cache to match HomeScreen
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final diff = await loadTextSizeDiff(Constants.defaultTextDiff);
      if (!mounted) return;
      setState(() {
        _custTextSize = Constants.calcTextSize(diff);
        _custTitleSize = Constants.calcTitleSize(diff);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final headText = widget.passage.heads[widget.headIndex];

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: ListView(
          children: [
            // Title styled like HomeScreen
            Text(
              widget.passage.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: _custTitleSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            // Head styled like HomeScreen
            Text(
              headText,
              style: TextStyle(
                fontSize: _custTextSize,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Arguments holder so we can pass data via routes
class SearchDetailsArgs {
  final Passage passage;
  final int headIndex;

  SearchDetailsArgs({required this.passage, required this.headIndex});
}

import 'package:flutter/material.dart';
import 'package:holobooth/assets/assets.dart';
import 'package:holobooth/in_experience_selection/in_experience_selection.dart';
import 'package:holobooth/l10n/l10n.dart';
import 'package:holobooth_ui/holobooth_ui.dart';

class PropsSelectionTabBarView extends StatefulWidget {
  const PropsSelectionTabBarView({
    super.key,
    this.initialIndex = 0,
  });

  @visibleForTesting
  static const glassesTabKey = ValueKey('glasses_tab');

  @visibleForTesting
  static const clothesTabKey = ValueKey('clothes_tab');

  @visibleForTesting
  static const othersTabKey = ValueKey('others_tab');

  final int initialIndex;

  @override
  State<PropsSelectionTabBarView> createState() =>
      _PropsSelectionTabBarViewState();
}

class _PropsSelectionTabBarViewState extends State<PropsSelectionTabBarView>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            context.l10n.propsTabTitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: HoloBoothColors.white),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Theme(
            data: ThemeData(
              tabBarTheme: const TabBarTheme(
                unselectedLabelColor: HoloBoothColors.gray,
                labelColor: HoloBoothColors.propTabSelection,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: HoloBoothColors.propTabSelection,
                  ),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                _PropSelectionTab(
                  assetGenImage: Assets.props.hatsIcon,
                ),
                _PropSelectionTab(
                  key: PropsSelectionTabBarView.glassesTabKey,
                  assetGenImage: Assets.props.glassesIcon,
                ),
                _PropSelectionTab(
                  key: PropsSelectionTabBarView.clothesTabKey,
                  assetGenImage: Assets.props.clothes,
                ),
                _PropSelectionTab(
                  key: PropsSelectionTabBarView.othersTabKey,
                  assetGenImage: Assets.props.othersIcon,
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _tabController,
            children: const [
              HatsSelectionTabBarView(),
              GlassesSelectionTabBarView(),
              ClothesSelectionTabBarView(),
              MiscellaneousSelectionTabBarView(),
            ],
          ),
        ),
        const SizedBox(height: 10)
      ],
    );
  }
}

class _PropSelectionTab extends StatefulWidget {
  const _PropSelectionTab({
    required this.assetGenImage,
    super.key,
  });

  final AssetGenImage assetGenImage;

  @override
  State<_PropSelectionTab> createState() => _PropSelectionTabState();
}

class _PropSelectionTabState extends State<_PropSelectionTab>
    with AutomaticKeepAliveClientMixin<_PropSelectionTab> {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Setting default icon size to avoid tap issues on testing.
    // As the child will be an image, if there is no default size, on tap will
    // throw a warning because the child will have no size
    final iconSize = IconTheme.of(context).size;
    return Tab(
      child: widget.assetGenImage.image(
        color: IconTheme.of(context).color,
        height: iconSize,
        width: iconSize,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:holobooth/in_experience_selection/in_experience_selection.dart';

class HatsSelectionTabBarView extends StatelessWidget {
  const HatsSelectionTabBarView({super.key});

  @visibleForTesting
  static Key hatSelectionKey(Hats item) {
    return Key('hat_selection_${item.name}');
  }

  @override
  Widget build(BuildContext context) {
    final selectedHat =
        context.select((InExperienceSelectionBloc bloc) => bloc.state.hat);
    return PropsScrollView(
      itemBuilder: (context, index) {
        final item = Hats.values[index];
        return PropSelectionElement(
          key: hatSelectionKey(item),
          onTap: () {
            context
                .read<InExperienceSelectionBloc>()
                .add(InExperienceSelectionHatToggled(item));
          },
          name: item.name,
          isSelected: item == selectedHat,
          imageProvider: item.toImageProvider(),
        );
      },
      itemCount: Hats.values.length,
    );
  }
}

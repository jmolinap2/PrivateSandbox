import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;

  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildKey(String label, {VoidCallback? onTap, Widget? child}) {
      return Expanded(
        child: AspectRatio(
          aspectRatio: 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(
                child: child ?? Text(label, style: Theme.of(context).textTheme.headlineSmall),
              ),
            ),
          ),
        ),
      );
    }

    Widget buildRow(List<Widget> children) => Row(children: children);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildRow([
          buildKey('1', onTap: () => onDigit('1')),
          buildKey('2', onTap: () => onDigit('2')),
          buildKey('3', onTap: () => onDigit('3')),
        ]),
        buildRow([
          buildKey('4', onTap: () => onDigit('4')),
          buildKey('5', onTap: () => onDigit('5')),
          buildKey('6', onTap: () => onDigit('6')),
        ]),
        buildRow([
          buildKey('7', onTap: () => onDigit('7')),
          buildKey('8', onTap: () => onDigit('8')),
          buildKey('9', onTap: () => onDigit('9')),
        ]),
        buildRow([
          buildKey(
            '',
            onTap: onBiometric,
            child: onBiometric == null ? null : const Icon(Icons.fingerprint),
          ),
          buildKey('0', onTap: () => onDigit('0')),
          buildKey(
            '',
            onTap: onBackspace,
            child: const Icon(Icons.backspace_outlined),
          ),
        ]),
      ],
    );
  }
}

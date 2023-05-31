import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final bool isLoading;
  final String text;
  final VoidCallback onPressed;

  const Button({
    Key? key,
    this.isLoading = false,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280.0,
      child: MaterialButton(
        color: Colors.black,
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(
                height: 24.0,
                width: 24.0,
                child: CircularProgressIndicator(),
              )
            : Text(
                text,
                style: const TextStyle(color: Colors.white),
              ),
      ),
    );
  }
}

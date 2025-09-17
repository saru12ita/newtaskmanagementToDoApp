import 'package:flutter/material.dart';
import 'package:task_management_todo/widgets/size_config.dart';

Color kPrimaryColor = const Color(0xffFC9D45);
Color kSecondaryColor = const Color(0xff573353);

TextStyle get kTitle => TextStyle(
      fontFamily: 'Klasik',
      fontSize: SizeConfig.blockSizeH! * 6.5, // dynamic font size
      color: kSecondaryColor,
      fontWeight: FontWeight.bold,
    );

TextStyle get kBodyText1 => TextStyle(
      color: kSecondaryColor,
      fontSize: SizeConfig.blockSizeH! * 4,
      fontWeight: FontWeight.w500,
    );
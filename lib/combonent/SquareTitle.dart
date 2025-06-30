import 'package:flutter/material.dart';

class SquareTitle extends StatelessWidget{
  final String imagepath;
  final Function()? ontap;
  const SquareTitle({super.key , required this.imagepath, required this.ontap});

  @override
  Widget build(BuildContext context){
    return GestureDetector(
      onTap: ontap,
      child: Container(
        padding: EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(15.0),
          color: Colors.white,
        ),
        child: Image.asset(imagepath,
          height: 65,
        ),
      ),
    );
  }
}



import 'package:flutter/material.dart';

Column rank({
  required double radius,
  required double height,
  required String image,
  required String name,
  required String point,
}) {
  return Column(
    children: [
      CircleAvatar(
        radius: radius,
        backgroundImage: image == ''
            ? AssetImage('assets/images/default-avatar.jpg')
                as ImageProvider<Object>
            : NetworkImage(image),
      ),
      SizedBox(
        height: height,
      ),
      Container(
        width: 100,
        child: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
      ),
      SizedBox(
        height: height,
      ),
      Container(
        height: 25,
        width: 70,
        decoration: BoxDecoration(
            color: Colors.black54, borderRadius: BorderRadius.circular(50)),
        child: Row(
          children: [
            const SizedBox(
              width: 5,
            ),
            const Icon(
              Icons.bolt,
              color: Color.fromARGB(255, 255, 187, 0),
            ),
            const SizedBox(
              width: 5,
            ),
            Text(
              point,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    ],
  );
}

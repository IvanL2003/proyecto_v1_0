import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class Pantalla2 extends StatefulWidget {
  final String item;

  const Pantalla2({super.key, required this.item});

  @override
  State<Pantalla2> createState() => _Pantalla2State();
}

class _Pantalla2State extends State<Pantalla2> {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item), toolbarHeight: 70),
      body: Stack(
        children: [
          Container(color: Color(0XFF4CE489)),
          Center(
            child: Card(
              color: Colors.white,
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     Image.asset(
                      'assets/images/${widget.item}.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),


                    const SizedBox(height: 20),
                    Text(
                      "Texto explicativo de ${widget.item.toLowerCase()}",
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

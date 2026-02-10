import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class Pantalla3 extends StatefulWidget {
  final String item;

  const Pantalla3({super.key, required this.item});

  @override
  State<Pantalla3> createState() => _Pantalla3State();
}

class _Pantalla3State extends State<Pantalla3> {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF16213e),
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 70,
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFF1a1a2e)),
          Center(
            child: Card(
              color: const Color(0xFF16213e),
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //  Image.network(
                    //   'images/${widget.item}.png',
                    //   width: 200,
                    //   height: 200,
                    //   fit: BoxFit.cover,
                    // ),


                    const SizedBox(height: 20),
                    Text(
                      "Texto explicativo de ${widget.item.toLowerCase()}",
                      style: const TextStyle(fontSize: 18, color: Colors.white70),
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

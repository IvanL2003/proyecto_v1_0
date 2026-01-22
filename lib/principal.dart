import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_v1_0/pantalla2.dart';
import 'package:proyecto_v1_0/pantalla3.dart';
import 'package:proyecto_v1_0/pantalla4.dart';
import 'package:proyecto_v1_0/pantalla_curso.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class Principal extends StatefulWidget {
  const Principal({super.key});

  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  int _selectedIndex = 0;
  String selectedLanguage = 'Inglés'; // valor inicial
  final List<String> languages = ['Español', 'Inglés', 'Francés'];

  // Sustantivos más usados en español
  List<String> items = [
    'Tiempo', 'Persona', 'Año', 'Dia', 'Cosa',
    'Hombre', 'Mujer', 'Vida', 'Mano', 'Parte',

    // 'Niño', 'Mundo', 'Momento', 'Trabajo', 'Lugar',
    // 'Caso', 'Punto', 'Gente', 'Problema', 'Forma',
    // 'Ciudad', 'País', 'Noche', 'Agua', 'Familia',
    // 'Historia', 'Mes', 'Dinero', 'Palabra', 'Camino',
    // 'Sociedad', 'Padre', 'Madre', 'Amigo', 'Cuerpo',
    // 'Idea', 'Niña', 'Hijo', 'Nombre', 'Realidad',
    'Rojo', 'Azul', 'Verde', 'Amarillo', 'Negro',
    'Blanco', 'Gris', 'Naranja', 'Marron', 'Rosa',
    // 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
    // 'k', 'l', 'm', 'n', 'ñ', 'o', 'p', 'q', 'r', 's',
    // 't', 'u', 'v', 'w', 'x', 'y', 'z'
  ];

  final List<Article> _articles = [
    Article(
      title: "Instagram quietly limits ‘daily time limit’ option",
      author: "MacRumors",
      imageUrl: "https://picsum.photos/id/1000/960/540",
      postedOn: "Yesterday",
    ),
    Article(
      title: "Google Search dark theme goes fully black for some on the web",
      imageUrl: "https://picsum.photos/id/1010/960/540",
      author: "9to5Google",
      postedOn: "4 hours ago",
    ),
    Article(
      title: "Check your iPhone now: warning signs someone is spying on you",
      author: "New York Times",
      imageUrl: "https://picsum.photos/id/1001/960/540",
      postedOn: "2 days ago",
    ),
    Article(
      title:
          "Amazon’s incredibly popular Lost Ark MMO is ‘at capacity’ in central Europe",
      author: "MacRumors",
      imageUrl: "https://picsum.photos/id/1002/960/540",
      postedOn: "22 hours ago",
    ),
    Article(
      title:
          "Panasonic's 25-megapixel GH6 is the highest resolution Micro Four Thirds camera yet",
      author: "Polygon",
      imageUrl: "https://picsum.photos/id/1020/960/540",
      postedOn: "2 hours ago",
    ),
    Article(
      title: "Samsung Galaxy S22 Ultra charges strangely slowly",
      author: "TechRadar",
      imageUrl: "https://picsum.photos/id/1021/960/540",
      postedOn: "10 days ago",
    ),
    Article(
      title: "Snapchat unveils real-time location sharing",
      author: "Fox Business",
      imageUrl: "https://picsum.photos/id/1060/960/540",
      postedOn: "10 hours ago",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    items.sort((a, b) => a.compareTo(b));
    items = items.map((e) => e.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: Color(0XFF4CE489),
      body: Stack(
        children: [
          // Container(
          //     color: Color(0XFF4CE489)
          // ),

          // Center(child: _navBarItems[_selectedIndex].title),
          if (_selectedIndex == 0)
            Image.asset(
              'assets/images/Icon-192.png',
              // reemplaza con tu URL o Asset
              fit: BoxFit.cover,
            ),
          if (_selectedIndex == 3)
            Stack(
              children: [
                Positioned(
                  top: 30,
                  left: 20,
                  right: 90,
                  child: Material(
                    elevation: 4, // pequeña sombra para efecto "flotante"
                    borderRadius: BorderRadius.circular(30),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: const TextStyle(color: Colors.black),
                        // prefixIcon: const Icon(Icons.search, color: Colors.black54),
                        filled: true,
                        fillColor: const Color(0xFFF1F3F4),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Color(0xFF1A73E8),
                            width: 2,
                          ),
                        ),
                      ),
                      cursorColor: const Color(0xFF1A73E8),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 90),
                  // height: 400, // 👈 altura fija
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:
                      // ListView.builder(
                      //   itemCount: items.length,
                      //   itemBuilder: (context, index) {
                      //     return Card(
                      //       margin: const EdgeInsets.symmetric(
                      //         horizontal: 10,
                      //         vertical: 6,
                      //       ),
                      //       child: ListTile(
                      //         leading: const Icon(Icons.star),
                      //         title: Text(items[index]),
                      //         subtitle: const Text('Descripción del elemento'),
                      //         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      //       ),
                      //     );
                      //   },
                      GridView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: items.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, // 👈 3 elementos por fila
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1,
                            ),
                        itemBuilder: (context, index) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Pantalla2(item: items[index]),
                                ),
                              );
                            },
                            child: Container(
                              width: 150, // puedes ajustar el ancho fijo
                              height: 200, // puedes ajustar la altura fija
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Imagen en la parte superior
                                  Expanded(
                                    flex: 3,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                      child: Image.asset(
                                        'assets/images/${items[index]}.png',
                                        // reemplaza con tu URL o Asset
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  // Texto debajo de la imagen
                                  Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: Text(
                                        items[index],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          //   Positioned(
          //     top: 30,
          //     left: 20,
          //     right: 90,
          //     child: Material(
          //       elevation: 4, // pequeña sombra para efecto "flotante"
          //       borderRadius: BorderRadius.circular(30),
          //       child: TextField(
          //         decoration: InputDecoration(
          //           hintText: 'Search...',
          //           hintStyle: const TextStyle(color: Colors.black),
          //           // prefixIcon: const Icon(Icons.search, color: Colors.black54),
          //           filled: true,
          //           fillColor: const Color(0xFFF1F3F4),
          //           contentPadding: const EdgeInsets.symmetric(
          //             vertical: 0,
          //             horizontal: 20,
          //           ),
          //           border: OutlineInputBorder(
          //             borderRadius: BorderRadius.circular(30),
          //             borderSide: BorderSide.none,
          //           ),
          //           focusedBorder: OutlineInputBorder(
          //             borderRadius: BorderRadius.circular(30),
          //             borderSide: const BorderSide(
          //               color: Color(0xFF1A73E8),
          //               width: 2,
          //             ),
          //           ),
          //         ),
          //         cursorColor: const Color(0xFF1A73E8),
          //       ),
          //     ),
          //   ),
          // if (_selectedIndex == 3)
          //   Container(
          //     margin: const EdgeInsets.only(top: 90),
          //     // height: 400, // 👈 altura fija
          //     decoration: BoxDecoration(
          //       color: Colors.white.withOpacity(0.2),
          //       borderRadius: BorderRadius.circular(20),
          //     ),
          //     child:
          //     // ListView.builder(
          //     //   itemCount: items.length,
          //     //   itemBuilder: (context, index) {
          //     //     return Card(
          //     //       margin: const EdgeInsets.symmetric(
          //     //         horizontal: 10,
          //     //         vertical: 6,
          //     //       ),
          //     //       child: ListTile(
          //     //         leading: const Icon(Icons.star),
          //     //         title: Text(items[index]),
          //     //         subtitle: const Text('Descripción del elemento'),
          //     //         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          //     //       ),
          //     //     );
          //     //   },
          //     GridView.builder(
          //       padding: const EdgeInsets.all(10),
          //       itemCount: items.length,
          //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          //         crossAxisCount: 3, // 👈 3 elementos por fila
          //         crossAxisSpacing: 10,
          //         mainAxisSpacing: 10,
          //         childAspectRatio: 1,
          //       ),
          //       itemBuilder: (context, index) {
          //         return InkWell(
          //           borderRadius: BorderRadius.circular(12),
          //           onTap: () {
          //             Navigator.push(
          //               context,
          //               MaterialPageRoute(
          //                 builder: (_) => Pantalla2(item: items[index]),
          //               ),
          //             );
          //           },
          //           child: Container(
          //             width: 150, // puedes ajustar el ancho fijo
          //             height: 200, // puedes ajustar la altura fija
          //             decoration: BoxDecoration(
          //               color: Colors.white,
          //               borderRadius: BorderRadius.circular(12),
          //               boxShadow: [
          //                 BoxShadow(
          //                   color: Colors.black12,
          //                   blurRadius: 4,
          //                   offset: const Offset(2, 2),
          //                 ),
          //               ],
          //             ),
          //             child: Column(
          //               crossAxisAlignment: CrossAxisAlignment.stretch,
          //               children: [
          //                 // Imagen en la parte superior
          //                 Expanded(
          //                   flex: 3,
          //                   child: ClipRRect(
          //                     borderRadius: const BorderRadius.only(
          //                       topLeft: Radius.circular(12),
          //                       topRight: Radius.circular(12),
          //                     ),
          //                     child: Image.network(
          //                       'images/${items[index]}.png', // reemplaza con tu URL o Asset
          //                       fit: BoxFit.cover,
          //                     ),
          //                   ),
          //                 ),
          //                 // Texto debajo de la imagen
          //                 Expanded(
          //                   flex: 1,
          //                   child: Center(
          //                     child: Text(
          //                       items[index],
          //                       style: const TextStyle(
          //                         fontWeight: FontWeight.bold,
          //                         fontSize: 16,
          //                       ),
          //                       textAlign: TextAlign.center,
          //                     ),
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ),
          //         );
          //
          //       },
          //     ),
          //
          //   ),
          if (_selectedIndex == 1)
            Center(
              child: Container(
                // constraints: const BoxConstraints(maxWidth: 400),
                child: ListView.builder(
                  itemCount: _articles.length,
                  itemBuilder: (BuildContext context, int index) {
                    final item = _articles[index];
                    // return Container(
                    //   height: 136,
                    //   margin: const EdgeInsets.symmetric(
                    //     horizontal: 16,
                    //     vertical: 8.0,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     // color: Colors.teal,
                    //     border: Border.all(color: Colors.black),
                    //     borderRadius: BorderRadius.circular(8.0),
                    //   ),
                    //   padding: const EdgeInsets.all(8),
                    //   child: Row(
                    //     children: [
                    //       Expanded(
                    //         child: Column(
                    //           mainAxisAlignment: MainAxisAlignment.center,
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             Text(
                    //               item.title,
                    //               style: const TextStyle(
                    //                 fontWeight: FontWeight.bold,
                    //               ),
                    //               maxLines: 2,
                    //               overflow: TextOverflow.ellipsis,
                    //             ),
                    //             const SizedBox(height: 8),
                    //             Text(
                    //               "${item.author} · ${item.postedOn}",
                    //               style: Theme.of(context).textTheme.bodySmall,
                    //             ),
                    //             const SizedBox(height: 8),
                    //             Row(
                    //               mainAxisSize: MainAxisSize.min,
                    //               children:
                    //                   [
                    //                     Icons.bookmark_border_rounded,
                    //                     Icons.share,
                    //                     Icons.more_vert,
                    //                   ].map((e) {
                    //                     return InkWell(
                    //                       onTap: () {},
                    //                       child: Padding(
                    //                         padding: const EdgeInsets.only(
                    //                           right: 8.0,
                    //                         ),
                    //                         child: Icon(e, size: 16),
                    //                       ),
                    //                     );
                    //                   }).toList(),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //       Container(
                    //         width: 100,
                    //         height: 100,
                    //         // color: Colors.blue,
                    //         decoration: BoxDecoration(
                    //           color: Colors.grey,
                    //           borderRadius: BorderRadius.circular(8.0),
                    //           image: DecorationImage(
                    //             fit: BoxFit.cover,
                    //             image: NetworkImage(item.imageUrl),
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    //
                    // );
                    return InkWell(
                      onTap: () {
                        // Aquí haces la acción que tú quieras
                        // print("Pulsado el artículo: ${item.title}");

                        // Ejemplo: navegar
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PantallaCurso(),
                          ),
                        );
                      },

                      child: Container(
                        height: 136,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${item.author} · ${item.postedOn}",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children:
                                        [
                                          Icons.bookmark_border_rounded,
                                          Icons.share,
                                          Icons.more_vert,
                                        ].map((e) {
                                          return InkWell(
                                            onTap: () {
                                              print("Icono pulsado: $e");
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8.0,
                                              ),
                                              child: Icon(e, size: 16),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(8.0),
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(item.imageUrl),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          if (_selectedIndex == 2)
            const Pantalla4(),
          if (_selectedIndex == 4)
            Column(
              children: [
                const Expanded(flex: 2, child: _TopPortion()),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          "Richie Lorie",
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     FloatingActionButton.extended(
                        //       onPressed: () {},
                        //       heroTag: 'follow',
                        //       elevation: 0,
                        //       label: const Text("Follow"),
                        //       icon: const Icon(Icons.person_add_alt_1),
                        //     ),
                        //     const SizedBox(width: 16.0),
                        //     FloatingActionButton.extended(
                        //       onPressed: () {},
                        //       heroTag: 'mesage',
                        //       elevation: 0,
                        //       backgroundColor: Colors.red,
                        //       label: const Text("Message"),
                        //       icon: const Icon(Icons.message_rounded),
                        //     ),
                        //   ],
                        // ),
                        const SizedBox(height: 16),
                        const _ProfileInfoRow(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          Positioned(
            top: 25,
            right: 10,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.language, color: Color(0xff3F423E)),
              iconSize: 40,
              // color: Color(0xff3F423E),
              onSelected: (String value) {
                setState(() {
                  selectedLanguage = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Idioma cambiado a $value')),
                );
              },
              itemBuilder: (BuildContext context) {
                return languages.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xff6200ee),
        unselectedItemColor: const Color(0xff3F423E),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: _navBarItems,
      ),
    );
  }
}

final _navBarItems = [
  SalomonBottomBarItem(
    icon: const Icon(Icons.home),
    title: const Text("Home"),
    selectedColor: Colors.pink,
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.auto_stories),
    title: const Text("Curses"),
    selectedColor: Colors.pink,
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.camera_alt),
    title: const Text("Camera"),
    selectedColor: Colors.pink,
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.search),
    title: const Text("Search"),
    selectedColor: Colors.pink,
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.person),
    title: const Text("Profile"),
    selectedColor: Colors.pink,
  ),
];

class Article {
  final String title;
  final String imageUrl;
  final String author;
  final String postedOn;

  Article({
    required this.title,
    required this.imageUrl,
    required this.author,
    required this.postedOn,
  });
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow();

  final List<ProfileInfoItem> _items = const [
    ProfileInfoItem("Cursos", 2),
    ProfileInfoItem("Seguidores", 120),
    ProfileInfoItem("Seguidos", 200),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      constraints: const BoxConstraints(maxWidth: 400),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _items
            .map(
              (item) => Expanded(
                child: Row(
                  children: [
                    if (_items.indexOf(item) != 0) const VerticalDivider(),
                    Expanded(child: _singleItem(context, item)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _singleItem(BuildContext context, ProfileInfoItem item) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          item.value.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      Text(item.title, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class ProfileInfoItem {
  final String title;
  final int value;

  const ProfileInfoItem(this.title, this.value);
}

class _TopPortion extends StatelessWidget {
  const _TopPortion();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 50),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xff0043ba), Color(0xff006df1)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(
                        'https://as1.ftcdn.net/v2/jpg/00/64/67/52/1000_F_64675209_7ve2XQANuzuHjMZXP3aIYIpsDKEbF5dD.jpg'
                        // 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

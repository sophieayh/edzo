import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../combonent/HomeScreen.dart';
import '../combonent/MyCoursesScreen.dart';
import '../combonent/SearchScreen.dart';
import 'TeacherDashboard.dart';
import 'AdminDashboardPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String teacherName = '';
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  // دالة تجيب role من قاعدة البيانات
  Future<String> getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'student'; // كخيار افتراضي

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if(doc.data()?['role'] == "teacher" || doc.data()?['role'] == "admin"){
      final teacherId = FirebaseAuth.instance.currentUser?.email;
      teacherName = await FirebaseFirestore.instance.collection('teachers').doc(teacherId).get().then((value) => value.data()?['name'] ?? 'اسم غير مسجل');
    }
    return doc.data()?['role'] ?? 'student';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data!;
        final isTeacher = role == 'teacher';
        final isAdmin = role == 'admin';

        final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
        print("name issssssss $teacherName");
        // الصفحات حسب الدور
        final List<Widget> pages = [
          const HomeScreen(),
          const SearchScreen(),
          const MyCoursesScreen(),
        ];

        if (isTeacher || isAdmin) {
          pages.add(TeacherDashboard(teacherEmail: userEmail, teacherName: teacherName));
        }

        if (isAdmin) {
          pages.add(const AdminDashboardPage());
        }

        // عناصر شريط التنقل السفلي
        final List<BottomNavigationBarItem> navItems = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'My Courses',
          ),
        ];

        if (isTeacher || isAdmin) {
          navItems.add(const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Teacher',
          ));
        }

        if (isAdmin) {
          navItems.add(const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ));
        }

        // نتأكد الفهرس ما يتجاوز عدد الصفحات
        if (_selectedIndex >= pages.length) {
          _selectedIndex = 0;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('My App'),
            backgroundColor: Colors.black,
            actions: [
              IconButton(
                onPressed: signUserOut,
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
          body: pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.black,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: navItems,
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }
}

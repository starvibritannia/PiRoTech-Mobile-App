import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pirotech/models/batch_model.dart';
import 'services/firebase_service.dart' as myFirebase;
import 'services/notification_service.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  // Wajib ditambahkan jika main() menggunakan async
  WidgetsFlutterBinding.ensureInitialized();

  // Menyalakan mesin Firebase berdasarkan file konfigurasi yang baru saja di-generate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();

  runApp(const PiroTechApp());
}

class PiroTechApp extends StatelessWidget {
  const PiroTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PiRoTech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Warna latar belakang utama (krem/off-white)
        scaffoldBackgroundColor: const Color(0xFFF2F5F2),
        primaryColor: const Color(0xFF427D46),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF427D46), // Hijau PiRoTech
          secondary: Color(0xFFE8F1E9), // Hijau muda untuk aksen
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// HALAMAN 0: SPLASH SCREEN (LAYAR AWAL)
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Variabel untuk mengontrol apakah elemen sedang terlihat atau tidak
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    // 1. Memicu animasi Fade-In (Muncul) sesaat setelah aplikasi dibuka
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _isVisible = true; // Mengubah transparansi menjadi 1.0 (terlihat penuh)
      });
    });

    // 2. Memicu animasi Fade-Out (Menghilang) pada detik ke-2.2
    Future.delayed(const Duration(milliseconds: 2200), () {
      setState(() {
        _isVisible =
            false; // Mengubah transparansi menjadi 0.0 (menghilang perlahan)
      });
    });

    // 3. Berpindah halaman persis pada detik ke-3 (saat layarnya sudah putih bersih)
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      // Cek apakah user sudah login → route sesuai role
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final token = await user.getIdTokenResult();
          final role = token.claims?['role'] ?? 'operator';
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminDashboardShell(),
              ),
            );
          }
        } catch (_) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const AdminDashboardShell()),
            );
          }
        }
      } else {
        // User belum login — tampilkan halaman beranda (ada tombol Login)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainOverviewScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // AnimatedOpacity akan membuat transisi perubahan secara otomatis dan mulus
        child: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(
            milliseconds: 800,
          ), // Durasi efek fade (0.8 detik)
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Utama
              Image.asset('assets/pirotechlogo.png', height: 80),
              const SizedBox(height: 50),

              // Loading Bar ke Kanan
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    backgroundColor: Color(0xFFE8F1E9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF427D46),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Memuat sistem...',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// KERANGKA UTAMA & NAVIGASI BAWAH
// ==========================================
class MainOverviewScreen extends StatefulWidget {
  const MainOverviewScreen({super.key});

  @override
  State<MainOverviewScreen> createState() => _MainOverviewScreenState();
}

class _MainOverviewScreenState extends State<MainOverviewScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Daftar halaman dipindah ke sini agar bisa menerima fungsi dari BerandaScreen
    final List<Widget> pages = [
      BerandaScreen(
        onNavigateToPanduan: () {
          setState(() {
            _currentIndex = 1; // Pindah ke tab Panduan
          });
        },
        onNavigateToHubungi: () {
          setState(() {
            _currentIndex = 2; // Pindah ke tab Hubungi Kami
          });
        },
      ),
      const PanduanScreen(),
      const HubungiScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5F2),
        elevation: 0,
        title: Image.asset('assets/pirotechlogo.png', height: 35),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  // Perintah navigasi (berpindah) ke halaman LoginScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF427D46),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: pages[
          _currentIndex], // Menggunakan variabel pages yang ada di dalam build
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF427D46),
        unselectedItemColor: Colors.grey.shade400,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Panduan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.email_rounded),
            label: 'Hubungi',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// HALAMAN 1: BERANDA (DENGAN VIDEO HERO)
// ==========================================
class BerandaScreen extends StatefulWidget {
  // Menambahkan dua fungsi callback sebagai jembatan ke MainOverviewScreen
  final VoidCallback onNavigateToPanduan;
  final VoidCallback onNavigateToHubungi;

  const BerandaScreen({
    super.key,
    required this.onNavigateToPanduan,
    required this.onNavigateToHubungi,
  });

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  // Deklarasi DUA controller
  late VideoPlayerController _controller;
  late VideoPlayerController _controller2; // Untuk video kedua

  // ==========================================
  // VARIABEL UNTUK KALKULATOR BBM
  // ==========================================
  double _beratSampah = 0.0;
  int _selectedIndex = 3; // Default memilih index 3 (PP)

  // Data jenis plastik dan yield-nya (berdasarkan pirolysis-constants.ts)
  final List<Map<String, dynamic>> _plasticData = [
    {
      'name': 'PET',
      'desc': 'Botol Minum',
      'yield': 0.35,
      'img': 'assets/pet.webp',
    },
    {
      'name': 'HDPE',
      'desc': 'Botol Susu',
      'yield': 0.60,
      'img': 'assets/hdpe.webp',
    },
    {
      'name': 'LDPE',
      'desc': 'Kantong',
      'yield': 0.55,
      'img': 'assets/ldpe.webp',
    },
    {
      'name': 'PP',
      'desc': 'Tutup Botol',
      'yield': 0.55,
      'img': 'assets/pp.webp',
    },
    {'name': 'PS', 'desc': 'Styrofoam', 'yield': 0.65, 'img': 'assets/ps.webp'},
    {
      'name': 'Mix',
      'desc': 'Campuran',
      'yield': 0.45,
      'img': 'assets/mix.webp',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Inisialisasi Video 1 (Hero Section)
    _controller = VideoPlayerController.asset('assets/video-3d-pirotech.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.setVolume(0);
        _controller.setLooping(true);
        _controller.play();
      });

    // Inisialisasi Video 2 (Apa itu PiRoTech)
    _controller2 =
        VideoPlayerController.asset('assets/video-proses-pirolisis.mp4')
          ..initialize().then((_) {
            setState(() {});
            _controller2.setVolume(0);
            _controller2.setLooping(true);
            _controller2.play();
          });
  }

  @override
  void dispose() {
    // Jangan lupa buang memori KEDUA video saat halaman ditutup
    _controller.dispose();
    _controller2.dispose();
    super.dispose();
  }

  // Widget pembantu untuk membuat kartu Cara Kerja Alat secara seragam
  Widget _buildStepCard(
    String number,
    String title,
    String desc,
    String imagePath,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF427D46),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E5930),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  // Widget pembantu untuk kotak statistik Dampak Nyata
  Widget _buildImpactCard(String value, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white
            .withValues(alpha: 0.1), // Efek transparan (Glassmorphism)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pembantu untuk kotak Keunggulan Alat
  Widget _buildKeunggulanCard(
    IconData icon,
    String title,
    String desc,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF2E5930),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // Label "Teknologi Pirolisis Plastik"
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.recycling, size: 16, color: Color(0xFF427D46)),
                SizedBox(width: 8),
                Text(
                  'Teknologi Pirolisis Plastik',
                  style: TextStyle(
                    color: Color(0xFF427D46),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Judul Utama (Headline)
        const Text(
          'Ubah Sampah Plastik Menjadi Bahan Bakar Cair',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2E5930),
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),

        // Sub-judul (Deskripsi)
        const Text(
          'Alat pirolisis inovatif berbasis Internet of Things (IoT) yang mampu mengubah limbah plastik menjadi BBM setara bensin, dikembangkan oleh Program Studi Teknologi Rekayasa Komputer Sekolah Vokasi IPB University yang didukung oleh Program Pengabdian Masyarakat Terpadu Sekolah Vokasi IPB University di Kelurahan Mulyaharja periode 2025-2026.',
          style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Tombol Aksi
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onNavigateToPanduan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF427D46),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Lihat Panduan →',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onNavigateToHubungi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Hubungi Kami',
                  style: TextStyle(
                    color: Color(0xFF427D46),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // WIDGET VIDEO PLAYER
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                // Menampilkan indikator loading jika video masih dimuat
                : const SizedBox(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF427D46),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 40),

        // ==========================================
        // BAGIAN: APA ITU PIROTECH
        // ==========================================
        const Text(
          'Apa itu PiRoTech?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E5930),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _controller2.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller2.value.aspectRatio,
                    child: VideoPlayer(_controller2),
                  )
                : const SizedBox(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF427D46),
                      ),
                    ),
                  ),
          ),
        ),

        const Text(
          'PiRoTech (Plastic Pyrolisis Technology) adalah alat pengolah sampah plastik menjadi bahan bakar cair berbasis IoT menggunakan teknologi pirolisis proses dekomposisi termal plastik tanpa oksigen pada suhu (100–200°C).',
          style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
        ),
        const SizedBox(height: 12),
        const Text(
          'Dikembangkan oleh tim dosen dan mahasiswa Program Studi Teknologi Rekayasa Komputer Sekolah Vokasi IPB University, alat ini dirancang untuk skala komunitas dengan biaya terjangkau dan mudah dioperasikan.',
          style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
        ),
        const SizedBox(height: 40),

        // ==========================================
        // BAGIAN: CARA KERJA ALAT
        // ==========================================
        const Center(
          child: Text(
            'Cara Kerja Alat',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E5930),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Proses pirolisis mengubah plastik menjadi bahan bakar cair melalui 6 tahap sederhana yang aman dan terkendali.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
          ),
        ),
        const SizedBox(height: 32),

        // Memanggil helper method untuk menampilkan ke-6 langkah
        _buildStepCard(
          '1',
          'Sortir & Bersihkan',
          'Pilah sampah plastik sesuai jenis (PET, HDPE, PP, dll.). Bersihkan dari sisa makanan atau kotoran, lalu keringkan.',
          'assets/step-sortir.webp',
        ),
        _buildStepCard(
          '2',
          'Masukkan ke Reaktor',
          'Masukkan plastik yang sudah bersih dan kering ke dalam reaktor utama hingga batas aman kapasitas.',
          'assets/step-masukkan.webp',
        ),
        _buildStepCard(
          '3',
          'Tutup & Kunci Reaktor',
          'Pasang tutup kerucut dan kunci dengan klem pengunci hingga kedap udara. Pastikan semua sambungan rapat.',
          'assets/step-tutup.webp',
        ),
        _buildStepCard(
          '4',
          'Panaskan Bertahap',
          'Nyalakan sumber pemanas dan naikkan suhu secara bertahap. Proses pirolisis optimal terjadi pada suhu 300-450°C.',
          'assets/step-panaskan.webp',
        ),
        _buildStepCard(
          '5',
          'Kondensasi Uap',
          'Uap yang dihasilkan mengalir melalui pipa ke kondensor, di mana uap didinginkan dan berubah menjadi cairan bahan bakar.',
          'assets/step-kondensasi.webp',
        ),
        _buildStepCard(
          '6',
          'Tampung Hasil BBM',
          'Minyak pirolisis cair keluar dari ujung kondensor dan ditampung di wadah. Hasilnya siap digunakan.',
          'assets/step-hasil.webp',
        ),

        const SizedBox(height: 40), // Jarak aman untuk bagian selanjutnya
        // ==========================================
        // BAGIAN: DAMPAK NYATA & KALKULATOR BBM
        // ==========================================
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF386641), // Warna hijau gelap khas PiRoTech
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // --- Header Kalkulator ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kalkulator Estimasi BBM',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Masukkan berat dan jenis plastik',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Area Putih: Form Kalkulator (FULL INTERAKTIF) ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Berat Sampah (kg)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E5930),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Input Text Dinamis
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Contoh: 10',
                        filled: true,
                        fillColor: const Color(0xFFF2F5F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          // Update perhitungan saat angka diketik
                          _beratSampah = double.tryParse(value) ?? 0.0;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Jenis Plastik',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E5930),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Grid Pilihan Plastik Dinamis
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // 3 kolom ke samping
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _plasticData.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIndex =
                                  index; // Mengubah pilihan plastik
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE8F1E9)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF427D46)
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Menampilkan gambar dinamis sesuai jenis plastik
                                Image.asset(
                                  _plasticData[index]['img'],
                                  height: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _plasticData[index]['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? const Color(0xFF427D46)
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  _plasticData[index]['desc'],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // --- Hasil Perkiraan (Menghitung Otomatis) ---
                    const Text(
                      'Perkiraan Hasil Pengolahan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E5930),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Logika Perhitungan Matematika
                    Builder(
                      builder: (context) {
                        double currentYield =
                            _plasticData[_selectedIndex]['yield'];
                        // Konversi: berat * persentase yield / densitas BBM (0.815)
                        double estBbmLiters =
                            (_beratSampah * currentYield) / 0.815;
                        // Estimasi kasar residu padat (abu) sekitar 10% dari berat
                        double estResidu = _beratSampah * 0.10;

                        return Column(
                          children: [
                            // Kotak Hasil 1: BBM Cair
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF427D46),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Estimasi BBM Cair',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '${estBbmLiters.toStringAsFixed(2)} liter',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.water_drop,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              children: [
                                // Kotak Hasil 2: Residu Padat
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F1E9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Estimasi Residu',
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '${estResidu.toStringAsFixed(2)} kg',
                                          style: const TextStyle(
                                            color: Color(0xFF2E5930),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Kotak Hasil 3: Yield Rate (Efisiensi)
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F1E9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Yield Rate',
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '${(currentYield * 100).toInt()}%',
                                          style: const TextStyle(
                                            color: Color(0xFF2E5930),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40), // Jarak sebelum Keunggulan Alat
        // ==========================================
        // BAGIAN: KEUNGGULAN ALAT
        // ==========================================
        const Center(
          child: Text(
            'Keunggulan Alat PiRoTech',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E5930),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Dirancang untuk kemudahan, keamanan, dan efisiensi maksimal dalam mengolah sampah plastik menjadi energi terbarukan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
          ),
        ),
        const SizedBox(height: 24),

        // Grid 4 Kotak Keunggulan
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio:
              0.70, // Disesuaikan agar teks yang panjang tidak terpotong
          children: [
            _buildKeunggulanCard(
              Icons.security,
              'Aman & Terkendali',
              'Dilengkapi sensor suhu dan alarm otomatis untuk menjaga keselamatan.',
              const Color(0xFF427D46),
            ),
            _buildKeunggulanCard(
              Icons.speed,
              'Efisiensi Tinggi',
              'Yield rate hingga 60-70% untuk plastik PP, menghasilkan banyak BBM.',
              Colors.orange,
            ),
            _buildKeunggulanCard(
              Icons.eco,
              'Ramah Lingkungan',
              'Kurangi emisi CO2 hingga 2.9 kg per kg plastik dibanding pembakaran terbuka.',
              Colors.teal,
            ),
            _buildKeunggulanCard(
              Icons.payments,
              'Bernilai Ekonomis',
              'BBM pirolisis setara solar dapat digunakan sendiri atau dijual.',
              Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 40),

        // ==========================================
        // BAGIAN: IMPLEMENTASI DI LAPANGAN
        // ==========================================
        const Center(
          child: Text(
            'Implementasi di Lapangan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E5930),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Dokumentasi penggunaan alat PiRoTech dalam pengolahan sampah plastik di masyarakat.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
          ),
        ),
        const SizedBox(height: 24),

        // Galeri Foto (Otomatis melooping impl-1 sampai impl-6)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 foto ke samping
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0, // Bentuk foto persegi (kotak)
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/impl-${index + 1}.webp',
                fit: BoxFit.cover,
              ),
            );
          },
        ),

        const SizedBox(height: 40), // Jarak aman untuk bagian penutup nanti
        // ==========================================
        // BAGIAN: CTA PANDUAN PENGGUNAAN
        // ==========================================
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1E9), // Latar hijau sangat muda
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.menu_book, color: Color(0xFF427D46), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Panduan Penggunaan Alat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E5930),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Pelajari cara menggunakan alat PiRoTech dengan aman dan efektif — mulai dari jenis plastik yang diperbolehkan, langkah-langkah operasional, hingga FAQ seputar proses pirolisis.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: widget.onNavigateToPanduan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF427D46),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Lihat Panduan Lengkap →',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // ==========================================
        // BAGIAN: CTA HUBUNGI KAMI
        // ==========================================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            color: const Color(0xFF386641), // Latar hijau gelap
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Text(
                'Tertarik Menggunakan PiRoTech?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tim kami siap membantu Anda memahami lebih lanjut tentang teknologi pirolisis dan bagaimana PiRoTech dapat diterapkan di lokasi Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Info Kontak
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.email_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'pirotechsvip@gmail.com',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Sekolah Vokasi IPB, Bogor',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Tombol Hubungi
              ElevatedButton.icon(
                onPressed: widget.onNavigateToHubungi,
                icon: const Icon(
                  Icons.phone_outlined,
                  color: Color(0xFF2E5930),
                ),
                label: const Text(
                  'Hubungi Kami',
                  style: TextStyle(
                    color: Color(0xFF2E5930),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),

        // ==========================================
        // BAGIAN: FOOTER
        // ==========================================
        const Divider(color: Colors.black12, thickness: 1),
        const SizedBox(height: 32),

        // Kumpulan Logo
        Column(
          children: [
            Image.asset('assets/pirotechlogo.png', height: 45),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo-sv.png',
                  height: 40,
                ), // Pastikan nama file ini sesuai
                const SizedBox(width: 16),
                Image.asset(
                  'assets/logo-tekom.png',
                  height: 40,
                ), // Pastikan nama file ini sesuai
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Deskripsi Footer
        const Text(
          'Monitoring alat pengolah sampah plastik menjadi bahan bakar cair menggunakan teknologi pirolisis berbasis IoT.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 40),

        // Copyright
        const Center(
          child: Text(
            '© 2026 PiRoTech • Sekolah Vokasi IPB. All rights reserved.',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ==========================================
// HALAMAN 2: PANDUAN PENGGUNAAN ALAT
// ==========================================
class PanduanScreen extends StatelessWidget {
  const PanduanScreen({super.key});

  // Widget pembantu untuk daftar nomor Skema Alat
  Widget _buildSchemaItem(String number, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF427D46)),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF427D46),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E5930),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget pembantu untuk daftar FAQ yang bisa dibuka-tutup
  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Theme(
        // Menghilangkan garis pembatas bawaan bawaan ExpansionTile
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF2E5930),
            ),
          ),
          iconColor: const Color(0xFF427D46),
          collapsedIconColor: Colors.grey,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: const TextStyle(
                  color: Colors.black54,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pembantu untuk kotak Lakukan vs Hindari
  Widget _buildDoAndDontCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1E9), // Latar hijau muda
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Bagian Lakukan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF427D46),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Lakukan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E5930),
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Gunakan sarung tangan & masker, pastikan area berventilasi baik.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Awali pemanasan secara perlahan, catat durasi & hasil.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.black12, thickness: 1),
          const SizedBox(height: 16),

          // Bagian Hindari
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Hindari:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Membuka tutup saat alat masih dalam keadaan panas/bertekanan.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Memasukkan kemasan berlapis aluminium atau bahan yang basah.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Menjalankan kondensor tanpa pendinginan (jika tipe water-cooled).',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // --- Header Panduan ---
        const Center(
          child: Text(
            'Panduan Penggunaan Alat PiRoTech',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E5930),
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Halaman ini menjelaskan aturan bahan, langkah penggunaan alat, dan pertanyaan umum, dengan bahasa sederhana untuk publik.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
          ),
        ),
        const SizedBox(height: 32),

        // --- Pemberitahuan Penting (Kotak Peringatan) ---
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F0), // Latar merah muda pucat
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade200, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Visual Peringatan
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                // Pastikan file penting.webp ada di folder assets kamu
                child: Image.asset(
                  'assets/penting.webp',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 28,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Pemberitahuan Penting',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Dilarang menggunakan plastik/kemasan yang ada lapisan metalized film atau aluminium foil di dalamnya.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contoh: bungkus kopi instan, sachet bumbu, kemasan keripik yang mengkilap di bagian dalam.',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Kotak Putih: Alasan & Contoh Aman
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bagian Larangan
                          const Row(
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                color: Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Mengapa Dilarang?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Tidak menghasilkan minyak, hanya jadi limbah padat.\n• Menimbulkan kerak sangat keras & berisiko menyumbat.\n• Menghambat perpindahan panas (proses jadi tidak efisien).',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade300,
                              height: 1.6,
                            ),
                          ),

                          const Divider(
                            height: 32,
                            color: Color(0xFFF2F5F2),
                            thickness: 1.5,
                          ),

                          // Bagian Aman
                          const Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF427D46),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Contoh yang Aman:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF427D46),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '• Botol PET, HDPE, PP yang bersih & kering.\n• Plastik rumah tangga tanpa lapisan metal (bagian dalam tidak mengkilap).',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // ==========================================
        // BAGIAN: SKEMA ALAT
        // ==========================================
        Row(
          children: [
            // Ikon tanda seru di depan judul
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF427D46), width: 1.5),
              ),
              child: const Icon(
                Icons.priority_high,
                size: 16,
                color: Color(0xFF427D46),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Skema Bagian Alat',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E5930),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Gambar Skema 3D
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset('assets/skema.webp', fit: BoxFit.cover),
        ),
        const SizedBox(height: 24),

        // Daftar Penjelasan Komponen
        _buildSchemaItem(
          '1',
          'Reaktor Utama',
          'Wadah utama tempat sampah plastik dipanaskan secara kedap udara.',
        ),
        _buildSchemaItem(
          '2',
          'Tutup Kerucut',
          'Mengarahkan uap hasil pemanasan plastik agar naik ke atas.',
        ),
        _buildSchemaItem(
          '3',
          'Klem Pengunci',
          'Mengunci tutup kerucut ke reaktor agar tidak ada asap/uap yang bocor.',
        ),
        _buildSchemaItem(
          '4',
          'Pipa Penyalur Uap',
          'Jalan perpindahan uap panas dari reaktor menuju ke dalam kondensor.',
        ),
        _buildSchemaItem(
          '5',
          'Tabung Kondensor',
          'Sistem pendingin (berisi air) untuk mengubah uap kembali menjadi cairan BBM.',
        ),
        _buildSchemaItem(
          '6',
          'Rangka Kaki',
          'Besi penopang yang memastikan reaktor dan kondensor berdiri stabil.',
        ),
        _buildSchemaItem(
          '7',
          'Tungku Pemanas',
          'Sumber api (burner) berbahan bakar gas untuk memanaskan reaktor.',
        ),
        _buildSchemaItem(
          '8',
          'Keran Pengeluaran BBM',
          'Jalur keluarnya minyak pirolisis cair yang siap ditampung.',
        ),

        const SizedBox(height: 40),

        // ==========================================
        // BAGIAN: CARA PAKAI AMAN
        // ==========================================
        Row(
          children: [
            // Ikon centang di depan judul
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF427D46), width: 1.5),
              ),
              child: const Icon(
                Icons.check,
                size: 16,
                color: Color(0xFF427D46),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cara Pakai Aman',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E5930),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Gambar Cara Pakai Aman
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/aman.webp',
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
        const SizedBox(height: 24),

        // 6 Poin Teks Berurutan
        const Text(
          '1. Sortir & bersihkan plastik, pastikan kering.',
          style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
        ),
        const Text(
          '2. Masukkan plastik ke reaktor sampai batas aman.',
          style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
        ),
        const Text(
          '3. Tutup & kunci reaktor, cek semua sambungan rapat.',
          style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
        ),
        const Text(
          '4. Siapkan penampung minyak di ujung kondensor.',
          style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
        ),
        const Text(
          '5. Panaskan bertahap dan amati alat ukur lokal (termometer/manometer bila tersedia).',
          style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
        ),
        const Text(
          '6. Selesai → matikan pemanas, biarkan dingin, baru buka & bersihkan residu.',
          style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
        ),

        const SizedBox(height: 24),

        // Kotak Lakukan vs Hindari
        _buildDoAndDontCard(),

        const SizedBox(height: 40),

        // ==========================================
        // BAGIAN: FAQ (Pertanyaan Umum)
        // ==========================================
        const Text(
          'Pertanyaan Umum (FAQ)',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E5930),
          ),
        ),
        const SizedBox(height: 16),

        _buildFaqItem(
          'Apakah proses ini menghasilkan asap berbahaya?',
          'Selama reaktor dikunci rapat (kedap udara), proses pirolisis sangat minim asap. Asap hanya akan muncul jika terdapat kebocoran pada klem pengunci atau jika proses pemanasan belum stabil di menit-menit awal.',
        ),
        _buildFaqItem(
          'Berapa lama proses pemanasan berlangsung?',
          'Bergantung pada kapasitas plastik yang dimasukkan. Untuk skala kecil (5-10 kg), proses dari pemanasan awal hingga BBM menetes biasanya memakan waktu 2 hingga 4 jam.',
        ),
        _buildFaqItem(
          'Apakah BBM yang dihasilkan bisa langsung digunakan?',
          'BBM cair hasil pirolisis (setara solar/minyak tanah) bisa langsung digunakan untuk mesin diesel statis, mesin pertanian, atau kompor minyak. Namun, untuk kendaraan bermotor modern, disarankan melakukan proses pemurnian lanjutan.',
        ),
        _buildFaqItem(
          'Apa yang harus dilakukan pada sisa abu (residu)?',
          'Sisa pembakaran (char/residu hitam) di dalam reaktor bisa dibersihkan setelah alat benar-benar dingin. Residu ini bisa dimanfaatkan lebih lanjut sebagai briket padat atau campuran bahan bangunan ringan.',
        ),

        const SizedBox(height: 40), // Ruang lega di bagian bawah layar
      ],
    );
  }
}

// ==========================================
// HALAMAN 3: HUBUNGI KAMI
// ==========================================
class HubungiScreen extends StatefulWidget {
  const HubungiScreen({super.key});

  @override
  State<HubungiScreen> createState() => _HubungiScreenState();
}

class _HubungiScreenState extends State<HubungiScreen> {
  // --- 1. Controller untuk menangkap teks inputan (Email DIHAPUS) ---
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _pesanController = TextEditingController();

  @override
  void dispose() {
    // Wajib dibersihkan agar memori HP tidak bocor
    _namaController.dispose();
    _pesanController.dispose();
    super.dispose();
  }

  // --- 2. Fungsi Eksekusi Kirim Email ---
  Future<void> _kirimPesan() async {
    final nama = _namaController.text.trim();
    final pesan = _pesanController.text.trim();

    // Validasi: Cek apakah nama atau pesan kosong
    if (nama.isEmpty || pesan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Nama dan Pesan terlebih dahulu!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Meracik format email
    final emailTujuan = 'pirotechsvipb@gmail.com';
    final subjek = 'Pertanyaan/Kerja Sama PiRoTech - $nama';

    // Template pesan yang jauh lebih profesional (menggunakan Triple Quotes)
    final isiPesan = '''Halo Tim PiRoTech,

Perkenalkan, nama saya $nama. Saya menghubungi Anda melalui aplikasi PiRoTech terkait hal berikut:

$pesan

Terima kasih atas waktu dan perhatiannya. Saya tunggu respons dari tim PiRoTech.

Hormat saya,
$nama''';

    // Uri.encodeComponent digunakan agar karakter spasi dan enter (baris baru) terbaca rapi di Gmail
    final url = Uri.parse(
        'mailto:$emailTujuan?subject=${Uri.encodeComponent(subjek)}&body=${Uri.encodeComponent(isiPesan)}');

    try {
      // Membuka aplikasi Gmail / Email bawaan HP
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        // (Opsional) Mengosongkan form setelah pengguna kembali ke aplikasi
        _namaController.clear();
        _pesanController.clear();
      } else {
        throw 'Tidak dapat membuka aplikasi email.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka aplikasi email di HP Anda.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const Center(
          child: Text(
            'Hubungi Kami',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E5930),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Ada pertanyaan seputar PiRoTech atau potensi kerja sama? Silakan isi formulir di bawah atau hubungi kontak yang tersedia.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
          ),
        ),
        const SizedBox(height: 32),

        // --- Kotak Info Kontak ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1E9), // Latar hijau muda
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF427D46), width: 1),
          ),
          child: Column(
            children: [
              _buildContactItem(
                Icons.email_outlined,
                'Email',
                'pirotechsvipb@gmail.com',
              ),
              const Divider(height: 24, color: Colors.black12),
              _buildContactItem(
                Icons.location_on_outlined,
                'Lokasi',
                'Sekolah Vokasi IPB, Bogor',
              ),
              const Divider(height: 24, color: Colors.black12),
              _buildContactItem(
                Icons.phone_outlined,
                'Telepon/WhatsApp',
                '+62 857-2050-3618',
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // --- Form Pesan ---
        const Text(
          'Kirim Pesan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E5930),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField('Nama Lengkap', 'Masukkan nama Anda', _namaController),
        const SizedBox(height: 16),
        _buildTextField(
          'Pesan',
          'Tulis pesan, pertanyaan, atau penawaran Anda di sini...',
          _pesanController,
          maxLines: 4,
        ),
        const SizedBox(height: 24),

        // --- Tombol Kirim ---
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            // Memanggil fungsi kirim pesan saat ditekan
            onPressed: _kirimPesan,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF427D46),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Kirim Pesan Sekarang',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 40), // Jarak aman di bagian bawah
      ],
    );
  }

  // Method pembantu untuk Baris Info Kontak
  Widget _buildContactItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF427D46), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5930),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Method pembantu untuk Kolom Input (TextField) ditambahkan parameter controller
  Widget _buildTextField(
      String label, String hint, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E5930),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller, // Menghubungkan controller ke TextField
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF2F5F2), // Warna abu-abu kehijauan
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// HALAMAN 4: LOGIN ADMIN
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Variabel untuk menyembunyikan/menampilkan password
  bool _obscurePassword = true;

  // Controller yang sudah dikosongkan
  // Controller bawaan yang sudah ada
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // Sakelar loading
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose(); // Menggunakan nama aslimu: _passController
    super.dispose();
  }

  Future<void> _prosesLogin() async {
    // Menggunakan _passController
    if (_emailController.text.trim().isEmpty ||
        _passController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan Password tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(), // Menggunakan _passController
      );

      // KODE BARU: Simpan Log Login
      await FirebaseDatabase.instance.ref().child('notifications').push().set({
        'level': 'Info',
        'message': 'User ${_emailController.text.trim()} baru saja login.',
        'tipe': 'login',
        'user_email': _emailController.text.trim(),
        'timestamp': ServerValue.timestamp,
        'is_read': false,
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Cek role user → route ke halaman yang sesuai
        final user = FirebaseAuth.instance.currentUser;
        String role = 'operator';
        if (user != null) {
          try {
            final token = await user.getIdTokenResult();
            role = token.claims?['role'] ?? 'operator';
          } catch (_) {}
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboardShell(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        errorMessage = 'Email atau password salah!';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid!';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER HIJAU (Adaptasi panel kiri web) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              decoration: const BoxDecoration(
                color: Color(0xFF386641), // Hijau gelap PiRoTech
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tombol Kembali
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainOverviewScreen(),
                        ),
                        (route) =>
                            false, // Ini adalah kunci untuk menyapu bersih semua tumpukan halaman sebelumnya
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Kembali ke Beranda',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Logo Transparan Putih
                  Image.asset(
                    'assets/pirotechlogo.png',
                    height: 45,
                    color: Colors
                        .white, // Ajaib! Ini akan mewarnai ulang logomu menjadi putih solid
                  ),

                  const Text(
                    'Monitoring Alat\nPirolisis Plastik',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pantau dan kendalikan proses pengolahan sampah plastik menjadi bahan bakar cair secara real-time dari mana saja.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // --- FORM LOGIN (Adaptasi panel kanan web) ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: Color(0xFF427D46),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Masuk ke Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E5930),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masukkan kredensial untuk mengakses panel',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 32),

                  // Input Email
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E5930),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF2F5F2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Input Password
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E5930),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passController,
                        obscureText:
                            _obscurePassword, // Diatur oleh variabel boolean
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF2F5F2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          // Ikon Mata (Toggle Visibility)
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.black54,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword; // Membalik nilai boolean
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Tombol Masuk
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // 1. Panggil fungsi Firebase jika tidak sedang loading
                      onPressed: _isLoading ? null : _prosesLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF427D46),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      // 2. Tampilkan animasi mutar jika loading, tampilkan tulisan 'Masuk' jika tidak
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Akun dikelola oleh Admin PiRoTech.',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// KERANGKA UTAMA ADMIN (DASHBOARD SHELL)
// ==========================================
class AdminDashboardShell extends StatefulWidget {
  const AdminDashboardShell({super.key});

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  List<String> _titles = ['Overview', 'Dashboard Monitoring', 'Log Activity'];
  List<Widget> _pages = [
    const AdminOverviewScreen(),
    const AdminMonitoringScreen(),
    const AdminLogActivityScreen(),
  ];

  Future<void> _loadRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdTokenResult();
      final role = token.claims?['role'] as String?;
      if (mounted) {
        setState(() {
          _isAdmin = role == 'admin';
          if (_isAdmin) {
            _titles = [
              'Overview',
              'Dashboard Monitoring',
              'Log Activity',
              'Pengaturan',
            ];
            _pages = [
              const AdminOverviewScreen(),
              const AdminMonitoringScreen(),
              const AdminLogActivityScreen(),
              const AdminPengaturanScreen(),
            ];
          } else {
            _titles = [
              'Overview',
              'Dashboard Monitoring',
              'Log Activity',
            ];
            _pages = [
              const AdminOverviewScreen(),
              const AdminMonitoringScreen(),
              const AdminLogActivityScreen(),
            ];
          }
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  // ==========================================
  // --- KODE BARU: SISTEM SATPAM VIRTUAL ---
  // ==========================================
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _sensorSub;
  StreamSubscription<DatabaseEvent>? _settingsSub;

  // Variabel penampung pengaturan
  double _overheatLimit = 100.0;
  double _warningPercent = 90.0;
  bool _isPushEnabled = true;

  // Tracker status agar tidak spam data ke Firebase
  String _currentAlertLevel = 'Normal';

  @override
  void initState() {
    super.initState();
    _loadRole();
    _mulaiPantauSistem(); // Nyalakan satpam saat halaman dimuat
  }

  @override
  void dispose() {
    // Wajib dimatikan saat pindah halaman agar memori HP tidak bocor
    _sensorSub?.cancel();
    _settingsSub?.cancel();
    super.dispose();
  }

  void _mulaiPantauSistem() {
    // 1. Pantau perubahan 'settings' dari Firebase secara realtime
    _settingsSub = _dbRef.child('config').onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (mounted) {
          setState(() {
            _overheatLimit = (data['overheat_limit'] ?? 100.0).toDouble();
            _warningPercent = (data['warning_percent'] ?? 90.0).toDouble();
            _isPushEnabled = data['push_enabled'] ?? true;
          });
        }
      }
    });

    // 2. Pantau pergerakan suhu TERBARU dari sensor
    _sensorSub = _dbRef
        .child('sensor_data')
        .orderByKey()
        .limitToLast(1) // Hanya ambil 1 data paling bawah (terbaru)
        .onValue
        .listen((event) {
      if (event.snapshot.exists && _isPushEnabled) {
        // Karena menggunakan limitToLast, data dibungkus oleh kode unik (Push ID)
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        // Ekstrak isi data dari dalam kode unik tersebut
        final latestData = Map<String, dynamic>.from(
          data.values.first as Map,
        );

        // Cek dan ambil nilai temperature_c
        if (latestData.containsKey('temperature_c')) {
          double currentTemp = (latestData['temperature_c'] as num).toDouble();
          _cekAmbangBatas(currentTemp);
        }
      }
    });
  }

  void _cekAmbangBatas(double suhuSaatIni) {
    // Hitung titik threshold Warning berdasarkan angka pemicu Buzzer
    double warningThreshold = _overheatLimit * (_warningPercent / 100.0);
    String newLevel = 'Normal';

    // Klasifikasi level bahaya: Critical jika menyentuh batas Buzzer
    if (suhuSaatIni >= _overheatLimit) {
      newLevel = 'Critical';
    } else if (suhuSaatIni >= warningThreshold) {
      newLevel = 'Warning';
    }

    // SISTEM ANTI-SPAM: Hanya memproses jika status level berubah
    if (newLevel != _currentAlertLevel) {
      _currentAlertLevel = newLevel;

      if (newLevel != 'Normal') {
        _simpanRiwayatNotifikasi(newLevel, suhuSaatIni);
      }
    }
  }

  Future<void> _simpanRiwayatNotifikasi(String level, double suhu) async {
    String pesan = level == 'Critical'
        ? 'Suhu Kritis! ($suhu°C) melewati batas maksimal operasional.'
        : 'Peringatan! ($suhu°C) mendekati titik batas aman.';

    // Tampilkan notifikasi lokal TERLEBIH DAHULU, supaya selalu muncul di HP
    // meskipun penulisan riwayat ke Firebase gagal (misal masalah izin/rules).
    if (_isPushEnabled) {
      NotificationService().showNotification(
        id: level == 'Critical' ? 1 : 2, // ID unik agar notifikasi bisa ditimpa
        title:
            level == 'Critical' ? '🚨 BAHAYA OVERHEAT!' : '⚠️ Peringatan Suhu',
        body: pesan,
        isCritical: level == 'Critical',
      );
    }

    // Mendorong data ke dalam folder 'notifications' di Firebase (riwayat)
    try {
      await _dbRef.child('notifications').push().set({
        'level': level,
        'message': pesan,
        'temperature': suhu,
        'timestamp':
            ServerValue.timestamp, // Catat waktu akurat dari mesin Firebase
        'is_read': false,
      });
    } catch (e) {
      debugPrint('[notifikasi] Gagal menyimpan riwayat ke Firebase: $e');
    }
  }

  // Konfirmasi & eksekusi logout dari Firebase, lalu kembali ke beranda
  void _tampilkanKonfirmasiLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Konfirmasi Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E5930),
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin logout dari aplikasi?',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          // Tombol "Batal"
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          // Tombol "Ya, Logout"
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              // Kembali ke beranda (MainOverviewScreen)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainOverviewScreen(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ya, Logout'),
          ),
        ],
      ),
    );
  }

  // Ganti akun → pindah ke halaman login (input email & password)
  void _pindahKeLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Tambahkan fungsi untuk mencatat aktivitas ke Firebase
  void _tampilkanLaciNotifikasi(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height *
              0.6, // Tinggi laci 60% dari layar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Riwayat Peringatan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5930),
                ),
              ),
              const Divider(thickness: 1),
              Expanded(
                child: StreamBuilder(
                  // Mendengarkan folder 'notifications' secara real-time
                  stream: _dbRef.child('notifications').onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF427D46),
                        ),
                      );
                    }
                    if (!snapshot.hasData ||
                        snapshot.data!.snapshot.value == null) {
                      return const Center(
                        child: Text(
                          'Belum ada peringatan tercatat.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }

                    // Ambil dan olah data dari Firebase
                    Map<dynamic, dynamic> notifMap =
                        snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    List<Map<dynamic, dynamic>> notifList = [];
                    List<String> notifKeys = [];
                    notifMap.forEach((key, value) {
                      notifList.add(value);
                      notifKeys.add(key);
                    });

                    // Urutkan data berdasarkan waktu terbaru (Descending)
                    notifList.sort(
                      (a, b) =>
                          (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0),
                    );

                    return ListView.builder(
                      itemCount: notifList.length,
                      itemBuilder: (context, index) {
                        var notif = notifList[index];
                        bool isCritical = notif['level'] == 'Critical';

                        // Konversi timestamp menjadi format Tanggal & Jam
                        DateTime time = DateTime.fromMillisecondsSinceEpoch(
                          notif['timestamp'] ?? 0,
                        );
                        String formatWaktu =
                            "${time.day}/${time.month}/${time.year}  ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

                        return Card(
                          color: isCritical
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFFFF3E0),
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              isCritical
                                  ? Icons.warning_rounded
                                  : Icons.info_outline_rounded,
                              color: isCritical ? Colors.red : Colors.orange,
                            ),
                            title: Text(
                              notif['level'] ?? 'Peringatan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCritical ? Colors.red : Colors.orange,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  notif['message'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  formatWaktu,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF2F5F2,
      ), // Latar abu-abu kehijauan persis seperti web
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(
          color: Color(0xFF2E5930),
        ), // Warna hijau gelap untuk ikon hamburger
        title: Text(
          _titles[_selectedIndex], // Judul berubah otomatis sesuai menu
          style: const TextStyle(
            color: Color(0xFF2E5930),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // Profil pengguna — klik munculkan menu Logout / Ganti Akun
          Row(
            children: [
              // Nama Role & Email
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isAdmin ? 'Admin' : 'Operator',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E5930),
                    ),
                  ),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? '-',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4), // Dikecilkan biar nggak mepet
              // Menu Popup
              PopupMenuButton<String>(
                icon: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F1E9),
                  child: Icon(Icons.person, color: Color(0xFF427D46)),
                ),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'logout') {
                    _tampilkanKonfirmasiLogout(context);
                  } else if (value == 'ganti_akun') {
                    _pindahKeLogin(context);
                  } else if (value == 'notifikasi') {
                    _tampilkanLaciNotifikasi(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'notifikasi',
                    child: StreamBuilder<DatabaseEvent>(
                      stream: _dbRef
                          .child('notifications')
                          .orderByChild('is_read')
                          .equalTo(false)
                          .onValue,
                      builder: (context, snapshot) {
                        int unreadCount = 0;
                        if (snapshot.hasData &&
                            snapshot.data!.snapshot.value != null) {
                          unreadCount =
                              (snapshot.data!.snapshot.value as Map).length;
                        }
                        return Row(
                          children: [
                            Stack(
                              children: [
                                const Icon(Icons.notifications_none,
                                    color: Color(0xFF2E5930)),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 8,
                                        minHeight: 8,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            const Text('Notifikasi'),
                          ],
                        );
                      },
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'ganti_akun',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, color: Color(0xFF2E5930)),
                        SizedBox(width: 10),
                        Text('Ganti Akun'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 10),
                        Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Header Drawer (Logo PiRoTech)
            DrawerHeader(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
              ),
              child: Center(
                child: Image.asset(
                  'assets/pirotechlogo.png',
                  height: 45,
                ), // Pastikan logonya berwarna
              ),
            ),

            // 4 Menu Utama
            _buildDrawerItem(0, Icons.grid_view_rounded, 'Overview'),
            _buildDrawerItem(
              1,
              Icons.show_chart_rounded,
              'Dashboard Monitoring',
            ),
            _buildDrawerItem(2, Icons.list_alt_rounded, 'Log Activity'),
            if (_isAdmin)
              _buildDrawerItem(3, Icons.settings_outlined, 'Pengaturan'),

            const Spacer(),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }

  // Widget pembantu untuk mencetak baris menu di dalam Drawer
  Widget _buildDrawerItem(int index, IconData icon, String title) {
    bool isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFE8F1E9)
            : Colors.transparent, // Latar hijau muda jika aktif
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF427D46) : Colors.grey.shade600,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF2E5930) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => _onItemTapped(index),
      ),
    );
  }
}

// ==========================================
// MENU 1: ADMIN OVERVIEW
// ==========================================
class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  // Variabel Kalkulator
  double _beratSampah = 0.0;
  int _selectedIndex = 0; // Default PET

  // --- VARIABEL BARU: Sinkron Firebase (Ganti Timer lokal) ---
  Batch? _activeBatch;
  StreamSubscription<Batch?>? _batchSub;

  // --- VARIABEL STATISTIK BARU ---
  List<Batch> _completedBatches = [];
  StreamSubscription<List<Batch>>? _historySub;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();

    // Pasang mata-mata ke Firebase untuk dengerin status batch
    _batchSub = myFirebase.FirebaseService.instance
        .streamRunningBatch()
        .listen((batch) {
      if (mounted) {
        setState(() {
          _activeBatch = batch;
        });
      }
    });

    // Pasang mata-mata untuk Statistik Riwayat
    _historySub = myFirebase.FirebaseService.instance
        .streamBatchHistory()
        .listen((batches) {
      if (mounted) {
        setState(() {
          _completedBatches = batches;
          _isLoadingStats = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _batchSub?.cancel();
    _historySub?.cancel();
    super.dispose();
  }

  // Widget pembantu untuk memunculkan dialog konfirmasi
  void _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E5930),
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(color: Colors.black87, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Tutup tanpa aksi
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              onConfirm(); // Jalankan fungsi yang diminta
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF427D46),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _plasticData = [
    {
      'name': 'PET',
      'desc': 'Botol Minum',
      'yield': 0.35,
      'img': 'assets/pet.webp',
    },
    {
      'name': 'HDPE',
      'desc': 'Botol Susu',
      'yield': 0.60,
      'img': 'assets/hdpe.webp',
    },
    {
      'name': 'LDPE',
      'desc': 'Kantong',
      'yield': 0.55,
      'img': 'assets/ldpe.webp',
    },
    {
      'name': 'PP',
      'desc': 'Tutup Botol',
      'yield': 0.55,
      'img': 'assets/pp.webp',
    },
    {'name': 'PS', 'desc': 'Styrofoam', 'yield': 0.65, 'img': 'assets/ps.webp'},
    {
      'name': 'Mix',
      'desc': 'Campuran',
      'yield': 0.45,
      'img': 'assets/mix.webp',
    },
  ];

  // Widget pembantu untuk Kotak Ringkasan (Bawah)
  Widget _buildSummaryCard(
    IconData icon,
    String title,
    String value,
    String unit,
    String desc,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF427D46), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5930),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E5930),
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black45,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logika Matematika Kalkulator (Firebase-Driven)
    // Hitung total dari _completedBatches
    int totalBatches = _completedBatches.length;
    double totalWaste =
        _completedBatches.fold(0.0, (sum, b) => sum + b.wasteKg);
    double avgYield = totalBatches > 0
        ? _completedBatches.fold(
                0.0,
                (sum, b) =>
                    sum +
                    (b.fuelLiters != null && b.wasteKg > 0
                        ? (b.fuelLiters! / b.wasteKg)
                        : 0.0)) /
            totalBatches
        : 0.0;

    // Variabel kalkulator lokal untuk input pengguna
    double currentYield = _plasticData[_selectedIndex]['yield'];
    double estBbmLiters = (_beratSampah * currentYield) / 0.815;
    double estResidu = _beratSampah * 0.10;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // --- RINGKASAN STATISTIK DARI FIREBASE ---
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                  Icons.history,
                  'Total Batch',
                  totalBatches.toString(),
                  'x',
                  'Jumlah pembakaran yang berhasil diselesaikan.'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                  Icons.scale_rounded,
                  'Total Sampah',
                  totalWaste.toStringAsFixed(1),
                  'kg',
                  'Total berat sampah plastik yang sudah diolah.'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
            Icons.percent_rounded,
            'Rata-rata Yield',
            (avgYield * 100).toStringAsFixed(1),
            '%',
            'Efisiensi rata-rata dari seluruh pembakaran.'),

        const SizedBox(height: 24),
        const Text(
          'Konfigurasi operasional dan estimasi pengolahan alat PiRoTech.',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // --- KOTAK INPUT (PUTIH) ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.scale_rounded, color: Color(0xFF427D46)),
                  SizedBox(width: 8),
                  Text(
                    'Input Sampah',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E5930),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan berat dan jenis sampah plastik yang akan diolah untuk melihat simulasi hasil.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              const Text(
                'Berat Sampah (kg)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5930),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Contoh: 15',
                  filled: true,
                  fillColor: const Color(0xFFF2F5F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _beratSampah = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Jenis Plastik',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5930),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: _plasticData.length,
                itemBuilder: (context, index) {
                  bool isSelected = _selectedIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE8F1E9)
                            : const Color(0xFFF2F5F2),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF427D46)
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(_plasticData[index]['img'], height: 35),
                          const SizedBox(height: 8),
                          Text(
                            _plasticData[index]['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isSelected
                                  ? const Color(0xFF427D46)
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            _plasticData[index]['desc'],
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- KOTAK HASIL (HIJAU) ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF386641), // Hijau Gelap
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Perkiraan Hasil Pengolahan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Angka Utama (BBM)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.water_drop_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimasi BBM Cair',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: estBbmLiters.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const TextSpan(
                                text: ' liter',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Dua kotak kecil (Residu & Yield)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Residu Padat',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${estResidu.toStringAsFixed(2)} kg',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Yield Rate',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(currentYield * 100).toStringAsFixed(1)} %',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- LOGIKA TOMBOL KONTROL PROSES (Firebase-Driven) ---
        if (_activeBatch == null || _activeBatch!.status == 'completed')
          // TAMPILAN 1: JIKA BELUM MULAI ATAU SUDAH SELESAI
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showConfirmationDialog(
                  title: 'Mulai Proses?',
                  content:
                      'Pastikan plastik sudah dimasukkan, reaktor terkunci rapat, dan tabung kondensor terisi air. Lanjutkan?',
                  onConfirm: () async {
                    // Panggil fungsi FirebaseService
                    await myFirebase.FirebaseService.instance
                        .startFirebaseBatch(
                            _beratSampah,
                            _plasticData[_selectedIndex]['name'],
                            'unknown_user');
                  },
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Mulai Proses',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2F5F2),
                foregroundColor: const Color(0xFF2E5930),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          )
        else
          // TAMPILAN 2: JIKA SEDANG BERJALAN ATAU PAUSED
          Column(
            children: [
              // Angka Timer
              Text(
                'Status: ${_activeBatch!.status.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF427D46),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  // Tombol Jeda / Lanjutkan
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_activeBatch!.status == 'running') {
                          await myFirebase.FirebaseService.instance
                              .pauseFirebaseBatch(_activeBatch!.id,
                                  _activeBatch!.accumulatedMs);
                        } else {
                          await myFirebase.FirebaseService.instance
                              .resumeFirebaseBatch(_activeBatch!.id);
                        }
                      },
                      icon: Icon(
                        _activeBatch!.status == 'paused'
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                      ),
                      label: Text(
                        _activeBatch!.status == 'paused' ? 'Lanjutkan' : 'Jeda',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade50,
                        foregroundColor: Colors.orange.shade800,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.orange.shade200),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tombol Hentikan
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showConfirmationDialog(
                          title: 'Hentikan Proses?',
                          content:
                              'Proses akan dihentikan sepenuhnya dan data simulasi akan dicatat. Yakin?',
                          onConfirm: () async {
                            await myFirebase.FirebaseService.instance
                                .stopFirebaseBatch(
                              _activeBatch!.id,
                              _activeBatch!.accumulatedMs,
                              0.0, // Perlu dihitung/diambil dari estimasi
                              _activeBatch!.wasteKg,
                              _activeBatch!.plasticType,
                              _activeBatch!.originalStartTs ?? 0,
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text(
                        'Hentikan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

        const SizedBox(height: 40),

        // --- RINGKASAN PENGOLAHAN (STATISTIK) ---
        const Text(
          'Ringkasan Pengolahan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E5930),
          ),
        ),
        const SizedBox(height: 16),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            // Kartu 1: Data batch aktif
            _buildSummaryCard(
              Icons.bar_chart,
              'Sampah Masuk',
              _activeBatch != null
                  ? _activeBatch!.wasteKg.toStringAsFixed(1)
                  : '0.0',
              'kg',
              'Berat sampah plastik untuk batch ini.',
            ),
            // Kartu 2: Status batch
            _buildSummaryCard(
              Icons.circle_rounded,
              'Status',
              _activeBatch != null
                  ? _activeBatch!.status.toUpperCase()
                  : 'IDLE',
              '',
              'Status proses pembakaran saat ini dari Firebase.',
            ),
          ],
        ),

        const SizedBox(height: 40), // Jarak aman bawah
      ],
    );
  }
}

// ==========================================
// MENU 2: DASHBOARD MONITORING
// ==========================================
class AdminMonitoringScreen extends StatefulWidget {
  const AdminMonitoringScreen({super.key});

  @override
  State<AdminMonitoringScreen> createState() => _AdminMonitoringScreenState();
}

class _AdminMonitoringScreenState extends State<AdminMonitoringScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Menambahkan Subscriptions untuk mencegah kebocoran memori
  StreamSubscription<DatabaseEvent>? _sensorSub;
  StreamSubscription<DatabaseEvent>? _buzzerSub;

  bool _isBuzzerOn = false;
  double _currentTemp = 0.0;
  String _systemStatus = 'IDLE';
  double _maxTemp = 0.0;
  List<FlSpot> _chartData = const [FlSpot(0, 0)];

  // --- VARIABEL BARU: Sinkron Firebase ---
  Batch? _activeBatch;
  StreamSubscription<Batch?>? _batchSub;

  // --- VARIABEL HEARTBEAT (DETAK JANTUNG) ---
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();

    // 1. Dengerin Batch Aktif
    _batchSub = myFirebase.FirebaseService.instance
        .streamRunningBatch()
        .listen((batch) {
      if (mounted) {
        setState(() {
          _activeBatch = batch;
        });
      }
    });

    // Pendengar Kontrol Buzzer
    _buzzerSub = _dbRef.child('control/buzzer').onValue.listen((
      DatabaseEvent event,
    ) {
      if (event.snapshot.value != null && mounted) {
        setState(() {
          _isBuzzerOn = event.snapshot.value as bool;
        });
      }
    });

    // Pendengar Sensor Data (Terkoneksi dengan Batch)
    _sensorSub =
        _dbRef.child('sensor_data').onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null && mounted && _activeBatch != null) {
        List<FlSpot> spots = [];
        double latestTemp = 0.0;
        double highestTemp = 0.0;

        // Filter berdasarkan batch yang sedang jalan
        final readings =
            Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        final sortedKeys = readings.keys.toList()..sort();

        for (var key in sortedKeys) {
          final data = Map<String, dynamic>.from(readings[key] as Map);
          final timestamp = (data['timestamp'] ?? 0) as int;

          // Pastikan originalStartTs tidak null sebelum dibanding
          int startTs = _activeBatch?.originalStartTs ?? timestamp;

          // Hanya ambil data setelah batch mulai
          if (timestamp >= startTs) {
            double temp = (data['temperature_c'] ?? 0.0).toDouble();
            // X-Axis: Detik sejak batch mulai
            double elapsedSeconds = (timestamp - startTs) / 1000;

            spots.add(FlSpot(elapsedSeconds, temp));
            latestTemp = temp;
            if (temp > highestTemp) highestTemp = temp;
          }
        }

        setState(() {
          _chartData = spots.isNotEmpty ? spots : [const FlSpot(0, 0)];
          _currentTemp = latestTemp;
          _maxTemp = highestTemp;
          _systemStatus = _activeBatch!.status.toUpperCase();
        });
      }
    });

    // Jalankan mesin pengintai nyawa alat
    _startHeartbeatMonitor();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _batchSub?.cancel(); // Bersihkan listener batch
    _sensorSub?.cancel();
    _buzzerSub?.cancel();
    super.dispose();
  }

  // Fungsi Pintar Pengecek Alat Mati (Sync Batch)
  void _startHeartbeatMonitor() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _activeBatch == null) return;

      // Logika pemantauan bisa ditambahkan di sini jika perlu
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Pantau grafik suhu real-time dan kendalikan proses operasional.',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // --- 1. KARTU INDIKATOR ATAS ---
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.thermostat, color: Colors.grey, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'SUHU SAAT INI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _currentTemp.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E5930),
                            ),
                          ),
                          const TextSpan(
                            text: ' °C',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentTemp > 400
                                ? Colors.red
                                : const Color(0xFF427D46),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentTemp > 400
                              ? 'Suhu Kritis!'
                              : 'Dalam ambang aman',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.show_chart, color: Colors.grey, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'STATUS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        // Warna otomatis: Oranye jika nyala, Abu-abu jika mati
                        color: _systemStatus == 'RUNNING'
                            ? Colors.orange.shade700
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _systemStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- 2. KARTU GRAFIK SUHU ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_outlined,
                        color: Color(0xFF427D46),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Grafik Suhu Reaktor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E5930),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 180,
                width: double.infinity,
                child: _chartData.length <= 1
                    ? const Center(
                        child: Text(
                          'Menunggu alat beroperasi...',
                          style: TextStyle(color: Colors.black38, fontSize: 13),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade200,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) => Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                              left: BorderSide(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _chartData,
                              isCurved: true,
                              color: const Color(0xFF427D46),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(
                                  0xFF427D46,
                                ).withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Sampel: ${_chartData.length} data',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  Text(
                    'Puncak Tertinggi: ${_maxTemp.toStringAsFixed(1)} °C',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- 3. KARTU KONTROL BUZZER ---
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.volume_up_outlined, color: Color(0xFF427D46)),
                  SizedBox(width: 8),
                  Text(
                    'Kontrol Buzzer Manual',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E5930),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nyalakan/matikan alarm darurat.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  _dbRef.child('control/buzzer').set(!_isBuzzerOn);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isBuzzerOn
                        ? Colors.red.shade50
                        : const Color(0xFFF2F5F2),
                    border: Border.all(
                      color: _isBuzzerOn ? Colors.red : Colors.grey.shade300,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isBuzzerOn
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isBuzzerOn ? Icons.volume_up : Icons.volume_off,
                        size: 40,
                        color: _isBuzzerOn ? Colors.red : Colors.black45,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isBuzzerOn ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isBuzzerOn ? Colors.red : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tekan tombol untuk membunyikan alarm manual.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

// ==========================================
// MENU 3: LOG ACTIVITY & EXPORT CSV (DENGAN FILTER)
// ==========================================
class AdminLogActivityScreen extends StatefulWidget {
  const AdminLogActivityScreen({super.key});

  @override
  State<AdminLogActivityScreen> createState() => _AdminLogActivityScreenState();
}

class _AdminLogActivityScreenState extends State<AdminLogActivityScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // --- 1. VARIABEL STATE UNTUK DATA & PENCARIAN ---
  List<Map<dynamic, dynamic>> _allLogs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedKeys = [];
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _muatDataLog(); // Panggil data dari Firebase saat halaman dibuka
  }

  Future<void> _loadRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final token = await user.getIdTokenResult();
        if (mounted) {
          setState(() {
            _isAdmin = token.claims?['role'] == 'admin';
          });
        }
      } catch (_) {}
    }
  }

  // --- 2. FUNGSI TARIK DATA DARI FIREBASE ---
  void _muatDataLog() {
    debugPrint('[LogActivity] Mendengarkan log_activity...');
    _dbRef.child('log_activity').onValue.listen((event) {
      debugPrint('[LogActivity] Data diterima: ${event.snapshot.exists}');
      if (event.snapshot.exists && mounted) {
        Map<dynamic, dynamic> logs =
            event.snapshot.value as Map<dynamic, dynamic>;
        debugPrint('[LogActivity] Jumlah log: ${logs.length}');
        List<Map<dynamic, dynamic>> tempList = [];

        logs.forEach((key, value) {
          // HARUS DIBUAT VARIABEL BARU AGAR BISA DITAMBAHKAN 'key'
          var logData = Map<dynamic, dynamic>.from(value as Map);
          logData['key'] = key; // INI BARIS YANG TERLEWAT! Sangat wajib ada.
          tempList.add(logData);
        });

        // Urutkan dari yang terbaru (Descending)
        tempList.sort(
          (a, b) => (b['tanggal'] ?? '').compareTo(a['tanggal'] ?? ''),
        );

        setState(() {
          _allLogs = tempList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _allLogs = [];
          _isLoading = false;
        });
      }
    });
  }

  // --- 3. FUNGSI SAKTI: EXPORT KE CSV ---
  Future<void> _exportKeCSV(
    List<Map<dynamic, dynamic>> dataYangDiekspor,
  ) async {
    if (dataYangDiekspor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data untuk diekspor pada rentang ini!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 1. Buat Header (Baris Pertama Excel)
      List<List<dynamic>> barisData = [];
      barisData.add([
        'Tanggal & Jam',
        'Jenis Plastik',
        'Berat (kg)',
        'Yield (%)',
        'Estimasi BBM (Liter)',
        'Residu Padat (kg)',
        'Suhu Rata-rata (°C)',
        'Durasi Proses',
      ]);

      // 2. Masukkan Isi Data (Hanya data yang sedang tampil/difilter)
      for (var log in dataYangDiekspor) {
        DateTime tgl =
            DateTime.tryParse(log['tanggal'] ?? '') ?? DateTime.now();
        String tglRapi =
            "${tgl.day}/${tgl.month}/${tgl.year} ${tgl.hour.toString().padLeft(2, '0')}:${tgl.minute.toString().padLeft(2, '0')}";

        barisData.add([
          tglRapi,
          log['jenis_plastik'] ?? '-',
          log['berat_kg'] ?? 0,
          log['yield_persen'] ?? 0,
          log['bbm_liter'] ?? 0,
          log['residu_kg'] ?? 0,
          log['rata_rata_suhu'] ?? 0,
          log['durasi'] ?? '-',
        ]);
      }

      // 3. Konversi ke format CSV
      String csvData = const ListToCsvConverter().convert(barisData);

      // 4. Buat File Sementara di memori HP
      final direktori = await getTemporaryDirectory();
      final pathFile = '${direktori.path}/Log_Operasional_PiRoTech.csv';
      final file = File(pathFile);
      await file.writeAsString(csvData);

      // 5. Munculkan Menu Bagikan (Share) bawaan HP Android
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Laporan Data Operasional PiRoTech');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengekspor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- 4. FUNGSI MEMUNCULKAN KALENDER (DATE PICKER) ---
  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF427D46), // Warna header
              onPrimary: Colors.white, // Warna teks header
              onSurface: Color(0xFF2E5930), // Warna teks kalender
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Reset end date jika start date lebih maju dari end date
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Fungsi mengubah format tanggal bawaan menjadi dd/mm/yyyy
  String _formatDate(DateTime? date) {
    if (date == null) return 'dd/mm/yyyy';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Widget pembantu mencetak baris detail
  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? const Color(0xFF2E5930) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

// --- KODE BARU: FUNGSI HAPUS LOG ---
  void _hapusLogTerpilih() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Data?',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(
            'Apakah Anda yakin ingin menghapus ${_selectedKeys.length} log yang dipilih? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Hapus semua data terpilih dari Firebase secara otomatis
              for (String key in _selectedKeys) {
                await _dbRef.child('log_activity').child(key).remove();
              }
              setState(() {
                _selectedKeys
                    .clear(); // Bersihkan pilihan setelah sukses dihapus
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Data berhasil dihapus!'),
                      backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  // Widget pembantu mencetak 1 Kartu Riwayat
  Widget _buildHistoryCard(Map<dynamic, dynamic> log) {
    String logKey = (log['key'] ?? '').toString();
    bool isSelected = _selectedKeys.contains(logKey);

    DateTime tgl = DateTime.tryParse(log['tanggal'] ?? '') ?? DateTime.now();
    String tglRapi =
        "${tgl.day.toString().padLeft(2, '0')}/${tgl.month.toString().padLeft(2, '0')}/${tgl.year}, ${tgl.hour.toString().padLeft(2, '0')}:${tgl.minute.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFF0F7F1)
            : Colors.white, // Ubah warna latar jika dicentang
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isSelected ? const Color(0xFF427D46) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Kotak Centang (hanya admin)
                  if (_isAdmin)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: isSelected,
                        activeColor: const Color(0xFF427D46),
                        side: BorderSide(color: Colors.grey.shade400),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedKeys.add(logKey);
                            } else {
                              _selectedKeys.remove(logKey);
                            }
                          });
                        },
                      ),
                    ),
                  if (_isAdmin) const SizedBox(width: 12),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Color(0xFF427D46),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tglRapi,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E5930),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'COMPLETED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF427D46),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black12),
          const SizedBox(height: 12),
          _buildDetailRow('Berat Sampah', '${log['berat_kg']} kg'),
          _buildDetailRow('Jenis Plastik', log['jenis_plastik'] ?? '-'),
          _buildDetailRow('Yield Rate', '${log['yield_persen']} %'),
          _buildDetailRow('Durasi Proses', log['durasi'] ?? '-'),
          _buildDetailRow('Hasil BBM Cair', '${log['bbm_liter']} Liter',
              isHighlight: true),
          _buildDetailRow('Suhu Rata-rata', '${log['rata_rata_suhu'] ?? 0} °C'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- LOGIKA FILTER (Pencarian Teks & Rentang Tanggal) ---
    final filteredData = _allLogs.where((log) {
      // 1. Filter Pencarian Teks
      bool matchesSearch = (log['jenis_plastik'] ?? '')
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      // 2. Filter Tanggal
      bool matchesDate = true;
      DateTime? logDate = DateTime.tryParse(log['tanggal'] ?? '');

      if (logDate != null) {
        // Ambil hanya tanggalnya saja (tanpa jam) untuk akurasi filter
        DateTime dateOnly = DateTime(logDate.year, logDate.month, logDate.day);

        if (_startDate != null) {
          DateTime startOnly = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );
          if (dateOnly.isBefore(startOnly)) matchesDate = false;
        }
        if (_endDate != null) {
          DateTime endOnly = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
          );
          if (dateOnly.isAfter(endOnly)) matchesDate = false;
        }
      }

      return matchesSearch && matchesDate;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF9),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Riwayat lengkap setiap sesi pengolahan sampah plastik.',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // --- BAGIAN FILTER & PENCARIAN ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kolom Pencarian
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value; // Memperbarui variabel pencarian
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari jenis plastik (misal: PET)...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.black38,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    filled: true,
                    fillColor: const Color(0xFFF2F5F2),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Kolom Rentang Tanggal
                Row(
                  children: [
                    // Tanggal Awal
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(context, true), // Buka kalender
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(_startDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _startDate == null
                                      ? Colors.black38
                                      : Colors.black87,
                                ),
                              ),
                              const Icon(
                                Icons.calendar_month,
                                size: 16,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tombol Reset Kalender
                    if (_startDate != null || _endDate != null)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '-',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),

                    // Tanggal Akhir
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(context, false), // Buka kalender
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(_endDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _endDate == null
                                      ? Colors.black38
                                      : Colors.black87,
                                ),
                              ),
                              const Icon(
                                Icons.calendar_month,
                                size: 16,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tombol Aksi (Export CSV & Hapus)
                // Tombol Aksi (Export CSV, Pilih Semua, & Hapus)
                Row(
                  children: [
                    // 1. Tombol Export CSV (semua role bisa akses)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportKeCSV(filteredData),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text(
                          'Export CSV',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF427D46),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    // 2 & 3. Tombol Pilih Semua & Hapus (hanya admin)
                    if (_isAdmin) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              // Cek apakah semua data yang TAMPIL sudah terpilih
                              bool isAllSelected =
                                  _selectedKeys.length == filteredData.length &&
                                      filteredData.isNotEmpty;

                              if (isAllSelected) {
                                _selectedKeys.clear(); // Batal pilih semua
                              } else {
                                // Pilih semua data yang sedang tampil (difilter)
                                _selectedKeys = filteredData
                                    .map((log) => (log['key'] ?? '').toString())
                                    .toList();
                              }
                            });
                          },
                          icon: Icon(
                              _selectedKeys.length == filteredData.length &&
                                      filteredData.isNotEmpty
                                  ? Icons.deselect
                                  : Icons.checklist,
                              size: 18),
                          label: Text(
                              _selectedKeys.length == filteredData.length &&
                                      filteredData.isNotEmpty
                                  ? 'Batal Pilih'
                                  : 'Pilih Semua',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8F1E9),
                            foregroundColor: const Color(0xFF427D46),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                  color: Color(0xFF427D46), width: 1),
                            ),
                          ),
                        ),
                      ),

                      // 3. Tombol Hapus (Muncul jika ada yang dicentang)
                      if (_selectedKeys.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _hapusLogTerpilih,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: Text('Hapus (${_selectedKeys.length})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red.shade700,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.red.shade200),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // --- DAFTAR KARTU RIWAYAT (Dihasilkan dari filteredData) ---
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(color: Color(0xFF427D46)),
              ),
            )
          else if (filteredData.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text(
                  'Data tidak ditemukan atau masih kosong.',
                  style: TextStyle(color: Colors.black45),
                ),
              ),
            )
          else
            ...filteredData.map((data) => _buildHistoryCard(data)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ==========================================
// MENU 4: PENGATURAN SISTEM
// ==========================================
class AdminPengaturanScreen extends StatefulWidget {
  const AdminPengaturanScreen({super.key});

  @override
  State<AdminPengaturanScreen> createState() => _AdminPengaturanScreenState();
}

class _AdminPengaturanScreenState extends State<AdminPengaturanScreen> {
  // --- 1. PENGHUBUNG FIREBASE & STATUS LOADING ---
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  bool _isLoading = true;

  // --- 2. CONTROLLER BAWAAN ASLIMU ---
  final TextEditingController _buzzerTempController = TextEditingController(
    text: '',
  );
  final TextEditingController _warningSensitivityController =
      TextEditingController(text: '');

  // --- 3. VARIABEL TOGGLE SWITCH ---
  bool _isPushEnabled = true;

  // --- 4. SIKLUS HIDUP HALAMAN (INIT & DISPOSE) ---
  @override
  void initState() {
    super.initState();
    _muatPengaturan(); // Otomatis menarik data saat halaman dibuka
  }

  @override
  void dispose() {
    // Wajib ada agar memori HP tidak bocor
    _buzzerTempController.dispose();
    _warningSensitivityController.dispose();
    super.dispose();
  }

  // --- 5. FUNGSI TARIK DATA DARI FIREBASE ---
  Future<void> _muatPengaturan() async {
    try {
      // UBAH 1: Arahkan ke folder 'config' agar sama dengan ESP32
      final snapshot = await _dbRef.child('config').get();
      if (snapshot.exists && mounted) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          // UBAH 2: Baca dari kunci 'overheat_limit'
          _buzzerTempController.text = data['overheat_limit']?.toString() ?? '';

          _warningSensitivityController.text =
              data['warning_percent']?.toString() ?? '';
          _isPushEnabled = data['push_enabled'] ?? true;
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat pengaturan: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 6. FUNGSI SIMPAN DATA KE FIREBASE ---
  Future<void> _simpanPengaturan() async {
    if (_buzzerTempController.text.isEmpty ||
        _warningSensitivityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua kolom angka harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // UBAH 3: Simpan ke dalam folder 'config'
      await _dbRef.child('config').set({
        // UBAH 4: Simpan dengan nama kunci 'overheat_limit' agar dikenali ESP32
        'overheat_limit': double.tryParse(_buzzerTempController.text) ?? 100.0,

        'warning_percent':
            double.tryParse(_warningSensitivityController.text) ?? 90.0,
        'push_enabled': _isPushEnabled,
      });

      // KODE BARU: Simpan notifikasi perubahan threshold
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseDatabase.instance.ref().child('notifications').push().set({
        'level': 'Info',
        'message': 'Admin ${user?.email ?? 'Unknown'} mengubah threshold suhu.',
        'tipe': 'config_change',
        'user_email': user?.email ?? 'Unknown',
        'timestamp': ServerValue.timestamp,
        'is_read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan pengaturan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 7. WIDGET PEMBANTU ASLIMU (TIDAK ADA YANG DIUBAH) ---
  Widget _buildNumberInput(
    String label,
    TextEditingController controller, {
    String? suffix,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2E5930),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF2F5F2),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            suffixText: suffix,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertBox(
    String title,
    String desc,
    Color bgColor,
    Color textColor,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.8),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Konfigurasi ambang batas peringatan dan preferensi notifikasi.',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // --- KARTU 1: AMBANG BATAS SUHU ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F1E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: Color(0xFF427D46),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ambang Batas Suhu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E5930),
                        ),
                      ),
                      Text(
                        'Atur batas suhu aman operasional.',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Peringatan Alarm (Buzzer)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF427D46),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _buildNumberInput(
                'Nyalakan alarm jika suhu > ... °C',
                _buzzerTempController,
                hint: 'Contoh: 400',
              ),
              const SizedBox(height: 8),
              const Text(
                'Buzzer akan berbunyi secara otomatis saat suhu melewati batas ini.',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- KARTU 2: NOTIFIKASI & PERINGATAN ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F1E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: Color(0xFF427D46),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifikasi & Peringatan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E5930),
                        ),
                      ),
                      Text(
                        'Atur preferensi penerimaan alarm dari sistem.',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Metode Pengiriman',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF427D46),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text(
                  'Notifikasi Push (Perangkat)',
                  style: TextStyle(fontSize: 13),
                ),
                secondary: const Icon(
                  Icons.phone_android,
                  color: Colors.black54,
                  size: 20,
                ),
                activeThumbColor: const Color(0xFF427D46),
                contentPadding: EdgeInsets.zero,
                value: _isPushEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _isPushEnabled = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              const Text(
                'Sensitivitas Peringatan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF427D46),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _buildNumberInput(
                'Kirim peringatan "Warning" saat suhu mencapai ... % batas maks',
                _warningSensitivityController,
                suffix: '%',
                hint: 'Contoh: 90',
              ),
              const SizedBox(height: 8),
              const Text(
                'Peringatan awal sebelum suhu mencapai level kritis (Critical).',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
              const SizedBox(height: 24),

              // Kotak Warning & Critical
              _buildAlertBox(
                'Level: Warning',
                'Suhu mendekati batas aman',
                Colors.orange.shade50,
                Colors.orange.shade800,
                Icons.warning_amber_rounded,
              ),
              _buildAlertBox(
                'Level: Critical',
                'Suhu melewati batas aman — buzzer & notifikasi dikirim otomatis.',
                Colors.red.shade50,
                Colors.red.shade700,
                Icons.notifications_active,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanPengaturan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF427D46),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Pengaturan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

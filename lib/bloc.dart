import 'package:flutter/material.dart'; // Paket yang menyediakan berbagai widget dan alat UI untuk membangun aplikasi Flutter
import 'package:http/http.dart' as http; // Paket untuk melakukan HTTP request
import 'dart:convert'; // Paket untuk mengonversi data dari dan ke format JSON
import 'package:flutter_bloc/flutter_bloc.dart'; // Paket untuk menggunakan BLoC (Business Logic Component) dalam aplikasi Flutter
import 'package:equatable/equatable.dart'; // Mengimpor Equatable untuk mempermudah perbandingan objek

// Class untuk merepresentasikan data universitas
class University {
  final String name; // Properti untuk menyimpan nama universitas
  final String website; // Properti untuk menyimpan alamat website universitas

  University({
    required this.name,
    required this.website,
  }); // Konstruktor untuk inisialisasi properti

  // Factory method untuk membuat instance University dari JSON
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'], // Mendapatkan nama universitas dari JSON
      website: json['web_pages']
          [0], // Mendapatkan alamat website universitas dari JSON
    );
  }
}

// Event untuk mengambil data universitas berdasarkan negara
class UniversityEvent extends Equatable {
  final String country; // Properti untuk menyimpan negara

  UniversityEvent({required this.country}); // Konstruktor untuk event

  @override
  List<Object?> get props => [
        country
      ]; // Mendefinisikan properti yang akan digunakan untuk perbandingan objek
}

// State untuk menyimpan daftar universitas
class UniversityState extends Equatable {
  final List<University>
      universities; // Properti untuk menyimpan daftar universitas

  UniversityState({required this.universities}); // Konstruktor untuk state

  @override
  List<Object> get props => [
        universities
      ]; // Mendefinisikan properti yang akan digunakan untuk perbandingan objek
}

// Bloc untuk mengelola state negara dan daftar universitas
class UniversityBloc extends Bloc<UniversityEvent, UniversityState> {
  UniversityBloc()
      : super(UniversityState(universities: [])); // Konstruktor untuk Bloc

  @override
  Stream<UniversityState> mapEventToState(UniversityEvent event) async* {
    if (event is UniversityEvent) {
      try {
        final response = await http.get(Uri.parse(
            'http://universities.hipolabs.com/search?country=${event.country}'));

        if (response.statusCode == 200) {
          List<dynamic> data = json.decode(response.body);
          List<University> universities =
              data.map((json) => University.fromJson(json)).toList();
          yield UniversityState(
              universities:
                  universities); // Mengirimkan state baru dengan daftar universitas yang diperbarui
        } else {
          throw Exception('Failed to load university data');
        }
      } catch (e) {
        throw Exception('Failed to load university data');
      }
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider(
        create: (context) =>
            UniversityBloc(), // Membuat instance UniversityBloc dan menyediakannya ke dalam widget-tree
        child:
            UniversityList(), // Menampilkan widget UniversityList sebagai halaman utama
      ),
    );
  }
}

class UniversityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final universityBloc = BlocProvider.of<UniversityBloc>(
        context); // Mendapatkan instance UniversityBloc dari BlocProvider
    final List<String> countries = [
      'Indonesia',
      'Malaysia',
      'Singapore',
      'Thailand',
      'Vietnam'
    ]; // Daftar negara-negara ASEAN

    return Scaffold(
      appBar: AppBar(
        title: Text('University List'), // Judul AppBar
        actions: [
          DropdownButton<String>(
            value: countries[0], // Nilai default DropdownButton
            items: countries.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child:
                    Text(value), // Menampilkan nama negara di DropdownMenuItem
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                universityBloc.add(UniversityEvent(
                    country:
                        newValue)); // Mengirim event untuk mengambil data universitas berdasarkan negara yang dipilih
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<UniversityBloc, UniversityState>(
        builder: (context, state) {
          if (state is UniversityState) {
            return state.universities.isEmpty
                ? Center(
                    child:
                        CircularProgressIndicator()) // Menampilkan indikator progres jika daftar universitas kosong
                : ListView.builder(
                    itemCount: state.universities.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(state.universities[index]
                            .name), // Menampilkan nama universitas
                        subtitle: Text(state.universities[index]
                            .website), // Menampilkan alamat website universitas
                      );
                    },
                  );
          } else {
            return Center(
                child: Text(
                    'Failed to load university data')); // Menampilkan pesan kesalahan jika gagal mengambil data universitas
          }
        },
      ),
    );
  }
}

void main() {
  runApp(MyApp()); // Memulai aplikasi Flutter
}

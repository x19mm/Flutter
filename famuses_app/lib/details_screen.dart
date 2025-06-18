import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DetailsScreen extends StatefulWidget {
  final int personId;

  DetailsScreen({required this.personId});

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late Future<Map<String, dynamic>> _personDetails;
  late Future<List<dynamic>> _personImages;
  double _scale = 1.0; // State to control zoom level

  Future<Map<String, dynamic>> fetchPersonDetails() async {
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/person/${widget.personId}?api_key=2dfe23358236069710a379edd4c65a6b',
      ),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load person details');
    }
  }

  Future<List<dynamic>> fetchPersonImages() async {
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/person/${widget.personId}/images?api_key=2dfe23358236069710a379edd4c65a6b',
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['profiles'] ?? [];
    } else {
      throw Exception('Failed to load person images');
    }
  }

  void zoomIn() {
    setState(() {
      _scale = (_scale + 0.5).clamp(1.0, 5.0); // Increase scale, max 5.0
    });
  }

  void zoomOut() {
    setState(() {
      _scale = (_scale - 0.5).clamp(1.0, 5.0); // Decrease scale, min 1.0
    });
  }

  @override
  void initState() {
    super.initState();
    _personDetails = fetchPersonDetails();
    _personImages = fetchPersonImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: FutureBuilder<Map<String, dynamic>>(
          future: _personDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading...');
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Text('Details');
            }
            return Text(
              'Details about ${snapshot.data!['name'] ?? 'Unknown'}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _personDetails,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return Center(child: Text('No data available'));
                } else {
                  final person = snapshot.data!;
                  return Card(
                    color: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    margin: EdgeInsets.all(8.0),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Location of Birth: ${person['place_of_birth'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Popularity: ${person['popularity']?.toString() ?? 'N/A'}',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Job: ${person['known_for_department'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'BirthDay: ${person['birthday'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 20),
            Text(
              'Photos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            FutureBuilder<List<dynamic>>(
              future: _personImages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No images available'));
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final imagePath = snapshot.data![index]['file_path'];
                      final imageUrl =
                          'https://image.tmdb.org/t/p/w500$imagePath';
                      return Card(
                        color: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        margin: EdgeInsets.all(8.0),
                        child: Stack(
                          children: [
                            InteractiveViewer(
                              boundaryMargin: EdgeInsets.all(20.0),
                              minScale: 1.0,
                              maxScale: 5.0,
                              scaleEnabled: false,
                              // Disable pinch zoom
                              child: Transform.scale(
                                scale: _scale,
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: Text(
                                          'Image failed to load',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8.0,
                              right: 48.0, // Adjusted to avoid overlap
                              child: IconButton(
                                icon: Icon(Icons.zoom_in, color: Colors.white),
                                onPressed: zoomIn,
                              ),
                            ),
                            Positioned(
                              top: 8.0,
                              right: 8.0,
                              child: IconButton(
                                icon: Icon(Icons.zoom_out, color: Colors.white),
                                onPressed: zoomOut,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

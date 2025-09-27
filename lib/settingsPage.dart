import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:location/location.dart';
import 'services/database_service.dart';
import 'providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedTheme = 'system';
  // double? _universityLat;
  // double? _universityLng;
  // String? _universityAddress = 'Not selected';
  int? _selectedSemester;
  List<Map<String, dynamic>> _semesters = [];
  // GoogleMapController? _mapController;
  // final Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadSemesters();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getString('theme') ?? 'system';
      // _universityLat = prefs.getDouble('university_lat');
      // _universityLng = prefs.getDouble('university_lng');
      // _universityAddress = prefs.getString('university_address') ?? 'Not selected';
      _selectedSemester = prefs.getInt('selected_semester');
      _isLoading = false;
    });

    // if (_universityLat != null && _universityLng != null) {
    //   _updateMapMarker(LatLng(_universityLat!, _universityLng!));
    // }
  }

  Future<void> _loadSemesters() async {
    try {
      final semesters = await DatabaseService.instance.getAllSemesters();
      setState(() {
        _semesters = semesters;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading semesters: $e')),
      );
    }
  }

  Future<void> _saveThemeSetting(String theme) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.setTheme(theme);
    setState(() {
      _selectedTheme = theme;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Theme changed to $theme')),
    );
  }

  // Future<void> _saveLocationSetting(double lat, double lng, String address) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setDouble('university_lat', lat);
  //   await prefs.setDouble('university_lng', lng);
  //   await prefs.setString('university_address', address);
  //   setState(() {
  //     _universityLat = lat;
  //     _universityLng = lng;
  //     _universityAddress = address;
  //   });
  // }

  Future<void> _saveSemesterSetting(int semesterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_semester', semesterId);
    setState(() {
      _selectedSemester = semesterId;
    });
  }



  // void _updateMapMarker(LatLng position) {
  //   setState(() {
  //     _markers.clear();
  //     _markers.add(
  //       Marker(
  //         markerId: const MarkerId('university'),
  //         position: position,
  //         infoWindow: const InfoWindow(title: 'University Location'),
  //       ),
  //     );
  //   });
  // }

  // Future<void> _getCurrentLocation() async {
  //   Location location = Location();
  //   
  //   bool serviceEnabled = await location.serviceEnabled();
  //   if (!serviceEnabled) {
  //     serviceEnabled = await location.requestService();
  //     if (!serviceEnabled) return;
  //   }

  //   PermissionStatus permissionGranted = await location.hasPermission();
  //   if (permissionGranted == PermissionStatus.denied) {
  //     permissionGranted = await location.requestPermission();
  //     if (permissionGranted != PermissionStatus.granted) return;
  //   }

  //   LocationData locationData = await location.getLocation();
  //   if (locationData.latitude != null && locationData.longitude != null) {
  //     final newPosition = LatLng(locationData.latitude!, locationData.longitude!);
  //     _mapController?.animateCamera(CameraUpdate.newLatLng(newPosition));
  //     _updateMapMarker(newPosition);
  //     await _saveLocationSetting(
  //       locationData.latitude!,
  //       locationData.longitude!,
  //       'Current Location'
  //     );
  //   }
  // }

  // void _showLocationPicker() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => Dialog(
  //       child: Container(
  //         height: 500,
  //         width: double.maxFinite,
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           children: [
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 const Text(
  //                   'Select University Location',
  //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //                 ),
  //                 IconButton(
  //                   onPressed: () => Navigator.pop(context),
  //                   icon: const Icon(Icons.close),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 16),
  //             Expanded(
  //               child: GoogleMap(
  //                 initialCameraPosition: CameraPosition(
  //                   target: _universityLat != null && _universityLng != null
  //                       ? LatLng(_universityLat!, _universityLng!)
  //                       : const LatLng(0, 0),
  //                   zoom: 15,
  //                 ),
  //                 markers: _markers,
  //                 onMapCreated: (GoogleMapController controller) {
  //                   _mapController = controller;
  //                 },
  //                 onTap: (LatLng position) async {
  //                   _updateMapMarker(position);
  //                   await _saveLocationSetting(
  //                     position.latitude,
  //                     position.longitude,
  //                     'Selected Location'
  //                   );
  //                 },
  //               ),
  //             ),
  //             const SizedBox(height: 16),
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: ElevatedButton.icon(
  //                     onPressed: _getCurrentLocation,
  //                     icon: const Icon(Icons.my_location),
  //                     label: const Text('Use Current Location'),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 16),
  //                 Expanded(
  //                   child: ElevatedButton(
  //                     onPressed: () => Navigator.pop(context),
  //                     child: const Text('Done'),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Selection Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Theme',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<String>(
                    title: const Text('Light Theme'),
                    value: 'light',
                    groupValue: _selectedTheme,
                    onChanged: (value) => _saveThemeSetting(value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Dark Theme'),
                    value: 'dark',
                    groupValue: _selectedTheme,
                    onChanged: (value) => _saveThemeSetting(value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('System Default'),
                    value: 'system',
                    groupValue: _selectedTheme,
                    onChanged: (value) => _saveThemeSetting(value!),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // University Location Section - Commented out for now
          // Card(
          //   child: Padding(
          //     padding: const EdgeInsets.all(16),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Row(
          //           children: [
          //             Icon(
          //               Icons.location_on,
          //               color: Theme.of(context).colorScheme.primary,
          //             ),
          //             const SizedBox(width: 8),
          //             Text(
          //               'University Location',
          //               style: Theme.of(context).textTheme.titleMedium?.copyWith(
          //                 fontWeight: FontWeight.bold,
          //               ),
          //             ),
          //           ],
          //         ),
          //         const SizedBox(height: 16),
          //         ListTile(
          //           leading: const Icon(Icons.map),
          //           title: const Text('Location'),
          //           subtitle: Text(_universityAddress ?? 'Not selected'),
          //           trailing: const Icon(Icons.arrow_forward_ios),
          //           onTap: _showLocationPicker,
          //         ),
          //         if (_universityLat != null && _universityLng != null)
          //           Padding(
          //             padding: const EdgeInsets.only(top: 8),
          //             child: Text(
          //               'Coordinates: ${_universityLat!.toStringAsFixed(6)}, ${_universityLng!.toStringAsFixed(6)}',
          //               style: Theme.of(context).textTheme.bodySmall,
          //             ),
          //           ),
          //       ],
          //     ),
          //   ),
          // ),
          
          // const SizedBox(height: 16),
          
          // Semester Selection Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Academic Semester',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_semesters.isEmpty)
                    const ListTile(
                      leading: Icon(Icons.info),
                      title: Text('No semesters available'),
                      subtitle: Text('Add a semester from the dashboard first'),
                    )
                  else
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Select Semester',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedSemester,
                      items: _semesters.map((semester) {
                        return DropdownMenuItem<int>(
                          value: semester['id'],
                          child: Text('Semester ${semester['semesterNumber']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _saveSemesterSetting(value);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
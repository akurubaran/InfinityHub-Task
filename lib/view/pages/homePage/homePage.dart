// ignore_for_file: file_names, use_build_context_synchronously, library_private_types_in_public_api, prefer_typing_uninitialized_variables

import 'dart:async';

import 'package:flutter/material.dart';

// Importing Location Plugins
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

// Importing Google Maps Flutter
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Importing Intl
import 'package:intl/intl.dart';

// Importing Shared Preferences
import 'package:shared_preferences/shared_preferences.dart';

// Importing Speed Dial (For UI)
import 'package:simple_speed_dial/simple_speed_dial.dart';

// Importing Pages
import 'package:infinityhub_task/view/pages/exportPages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // "_currentDate" returns Date
  final String _currentDate = DateFormat("dd-MM-yyyy").format(DateTime.now());

  // "_currentTime" returns Time
  final String _currentTime = DateFormat("hh:mm:ss a").format(DateTime.now());

  final Completer<GoogleMapController> _gmapcontroller = Completer();

  // Intial Google Map View
  static const CameraPosition _kGoogle = CameraPosition(
    target: LatLng(13.067439, 80.237617),
    zoom: 15,
  );

  final List<Marker> _markers = <Marker>[];

  String? _currentAddress;
  Position? _currentPosition;

  // Location Permission Handler
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  // Fetches User Current Position
  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
      _getAddressFromLatLng(_currentPosition!);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  // Fetches User Current Address
  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
        _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
        '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        child: SafeArea(
          child: GoogleMap(
            initialCameraPosition: _kGoogle,
            buildingsEnabled: true,
            mapToolbarEnabled: true,
            zoomControlsEnabled: false,
            markers: Set<Marker>.of(_markers),
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              _gmapcontroller.complete(controller);
            },
          ),
        ),
      ),
      floatingActionButton: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 74),
              child: SpeedDial(

                speedDialChildren: <SpeedDialChild>[
                  SpeedDialChild(
                    child: const Icon(Icons.logout),
                    label: 'Logout',
                    onPressed: () async {
                      SharedPreferences sp =
                          await SharedPreferences.getInstance();
                      sp.remove('isLogin');
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()));
                    },
                    closeSpeedDialOnPressed: false,
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.delete),
                    label: 'Delete',
                    onPressed: () async {
                      SharedPreferences sp =
                          await SharedPreferences.getInstance();
                      sp.clear();
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()));
                    },
                  ),
                ],
                child: const Icon(Icons.menu),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: () async {
                _getCurrentPosition().then(
                  (value) async {
                    _markers.add(
                      Marker(
                        markerId: const MarkerId('1'),
                        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        infoWindow: const InfoWindow(
                          title: "TAP TO VIEW DETAILS",
                        ),
                        onTap: () {
                          AlertDialog alert = AlertDialog(
                            title: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text("Latitude : ${_currentPosition!.latitude}")
                                  ],
                                ),
                                const SizedBox( height: 10,),
                                Row(
                                  children: [
                                    Text("Longitude : ${_currentPosition!.longitude}")
                                  ],
                                ),
                                const SizedBox( height: 10,),
                                Row(
                                  children: [
                                    Flexible(
                                        child: Column(
                                          children: [
                                            Text(
                                              "Address : $_currentAddress",
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 3,
                                            ),
                                          ],
                                        ),
                                    ),
                                  ],
                                ),
                                const SizedBox( height: 10,),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Column(
                                        children: [
                                          Text(
                                            "Date : $_currentDate",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox( height: 10,),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Column(
                                        children: [
                                          Text(
                                            "Time : $_currentTime",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return alert;
                            },
                          );
                        },
                      ),
                    );
                    CameraPosition cameraPosition = CameraPosition(
                      target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      zoom: 15,
                    );
                    final GoogleMapController controller =
                        await _gmapcontroller.future;
                    controller.animateCamera(
                        CameraUpdate.newCameraPosition(cameraPosition));
                    setState(() {});
                  },
                );
              },
              child: const Icon(Icons.my_location),
            ),
          )
        ],
      ),
    );
  }
}

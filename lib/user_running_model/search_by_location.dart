import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elysium/widgets/non_recurring_post.dart';
import 'package:elysium/widgets/recurring_post.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_place/google_place.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SearchByLocation extends StatefulWidget {
  const SearchByLocation({super.key});

  @override
  SearchByLocationState createState() => SearchByLocationState();
}

class SearchByLocationState extends State<SearchByLocation> {
  bool primaryPage = true;
  TextEditingController locationController = TextEditingController();
  List<AutocompletePrediction> predictions = [];
  Timer? debounce;
  late GooglePlace googlePlace;
  DetailsResult? selectedLocation;
  GeoPoint? searchedGeopoint;
  double range = 10;
  bool currentlyRecurring = false;
  int selectedIndex = 0;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  bool isSearching = false;
  String titleText = '';
  bool showRangeCircle = true;
  bool isMapLoading = true;

  void switchPostType(int index) {
    setState(() {
      selectedIndex = index;
      currentlyRecurring = index == 1;
      _loadMarkers();
    });
  }

  void _loadMarkers() {
    if (searchedGeopoint == null) return;

    Set<Marker> markers = {};

    markers.add(
      Marker(
        markerId: const MarkerId('searched_location'),
        position: LatLng(
          searchedGeopoint!.latitude,
          searchedGeopoint!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(title: titleText),
      ),
    );

    List<String> postIDs = getNearbyPostIds(
      recurring: currentlyRecurring,
      currentLocation: searchedGeopoint!,
      range: range.toInt(),
    );

    Box usingBox = currentlyRecurring ? Hive.box('recurringBox') : Hive.box('nonRecurringBox');

    Map<String, List<String>> locationToPostIds = {};

    for (String id in postIDs) {
      var workingPost = usingBox.get(id);
      if (workingPost != null && workingPost['geolocation'] != null) {
        GeoPoint location = workingPost['geolocation'] as GeoPoint;
        String locationKey = '${location.latitude},${location.longitude}';

        if (!locationToPostIds.containsKey(locationKey)) {
          locationToPostIds[locationKey] = [];
        }
        locationToPostIds[locationKey]!.add(id);
      }
    }

    locationToPostIds.forEach((locationKey, ids) {
      List<String> latLng = locationKey.split(',');
      double latitude = double.parse(latLng[0]);
      double longitude = double.parse(latLng[1]);

      BitmapDescriptor markerIcon = currentlyRecurring
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

      markers.add(
        Marker(
          markerId: MarkerId(locationKey),
          position: LatLng(latitude, longitude),
          icon: markerIcon,
          onTap: () {
            _showPostDetails(ids, currentlyRecurring);
          },
        ),
      );
    });

    _circles = showRangeCircle
        ? {
            Circle(
              circleId: const CircleId('range_circle'),
              center: LatLng(
                searchedGeopoint!.latitude,
                searchedGeopoint!.longitude,
              ),
              radius: range * 1609.34,
              strokeColor: Colors.red.withOpacity(0.5),
              strokeWidth: 1,
              fillColor: Colors.transparent,
            ),
          }
        : {};

    setState(() {
      _markers = markers;
    });

    _adjustCameraToCircle();
  }

  void _adjustCameraToCircle() {
    final LatLng center = LatLng(
      searchedGeopoint!.latitude,
      searchedGeopoint!.longitude,
    );

    final double radiusInDegrees = range / 69;

    final LatLng southwest = LatLng(
      center.latitude - radiusInDegrees,
      center.longitude - radiusInDegrees,
    );
    final LatLng northeast = LatLng(
      center.latitude + radiusInDegrees,
      center.longitude + radiusInDegrees,
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: southwest, northeast: northeast),
        50,
      ),
    );
  }

  void _showPostDetails(List<String> postIds, bool isRecurring) {
    Box usingBox = isRecurring ? Hive.box('recurringBox') : Hive.box('nonRecurringBox');
    List<Map<String, dynamic>> posts = postIds.map((id) => usingBox.get(id) as Map<String, dynamic>).toList();

    String opportunityText = posts.length == 1 ? '1 opportunity available' : '${posts.length} opportunities available';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(opportunityText, style: GoogleFonts.montserrat()),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            body: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                var postData = posts[index];
                String docID = postIds[index];
                return isRecurring
                    ? recurringPost(
                        doc: postData,
                        shortened: true,
                        orgName: postData['org_name'],
                        role: 'user',
                        docID: docID,
                      )
                    : nonRecurringPost(
                        doc: postData,
                        shortened: true,
                        orgName: postData['org_name'],
                        role: 'user',
                        docID: docID,
                      );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    searchedGeopoint = GeoPoint(position.latitude, position.longitude);
    setState(() {
      primaryPage = false;
      titleText = 'Your Location';
      _loadMarkers();
    });
  }

  void showAutocomplete(String value) async {
    var result = await googlePlace.autocomplete.get(value);
    if (result != null && result.predictions != null && mounted) {
      setState(() {
        predictions = result.predictions!;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    String apiKey = 'AIzaSyDthfQsr548lxrHTDH7UrdY9vEa1xDf4Ns';
    googlePlace = GooglePlace(apiKey);
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  double calculateDistanceInMiles(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusMiles = 3958.8;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double distance = earthRadiusMiles * c;

    return distance;
  }

  List<String> getNearbyPostIds({
    required bool recurring,
    required GeoPoint currentLocation,
    required int range,
  }) {
    List<String> cardList = [];

    String boxName = recurring ? 'recurringBox' : 'nonRecurringBox';

    Box<dynamic> postsBox = Hive.box(boxName);

    for (var key in postsBox.keys) {
      var post = postsBox.get(key);

      GeoPoint postLocation = post['geolocation'];

      double distance = calculateDistanceInMiles(
        currentLocation.latitude,
        currentLocation.longitude,
        postLocation.latitude,
        postLocation.longitude,
      );

      if (distance <= range) {
        cardList.add(key as String);
      }
    }
    return cardList;
  }

  bool checkLocation() {
    if (selectedLocation != null) {
      if (selectedLocation!.geometry != null) {
        if (selectedLocation!.geometry!.location != null) {
          if (selectedLocation!.geometry!.location!.lat != null &&
              selectedLocation!.geometry!.location!.lng != null) {
            searchedGeopoint = GeoPoint(
              selectedLocation!.geometry!.location!.lat!,
              selectedLocation!.geometry!.location!.lng!,
            );
            return true;
          } else {
            return false;
          }
        } else {
          return false;
        }
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (searchedGeopoint != null) {
      _mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            searchedGeopoint!.latitude,
            searchedGeopoint!.longitude,
          ),
          12,
        ),
      );
    }
    _loadMarkers();
    setState(() {
      isMapLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle titleTextStyle = GoogleFonts.montserrat(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    final TextStyle buttonTextStyle = GoogleFonts.montserrat(
      fontSize: 14,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Search by Location",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 4,
      ),
      body: Stack(
        children: [
          if (!primaryPage)
            Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      searchedGeopoint != null ? searchedGeopoint!.latitude : 0.0,
                      searchedGeopoint != null ? searchedGeopoint!.longitude : 0.0,
                    ),
                    zoom: 12,
                  ),
                  markers: _markers,
                  circles: _circles,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                if (isMapLoading)
                  Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white.withOpacity(0.95),
              child: isSearching
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: locationController,
                            decoration: InputDecoration(
                              hintText: 'Enter a location',
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    isSearching = false;
                                    predictions = [];
                                  });
                                },
                              ),
                            ),
                            onChanged: (text) {
                              if (debounce?.isActive ?? false) debounce!.cancel();
                              debounce = Timer(const Duration(milliseconds: 500), () {
                                if (text.isNotEmpty) {
                                  showAutocomplete(text);
                                } else {
                                  setState(() {
                                    predictions = [];
                                    selectedLocation = null;
                                  });
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: () {
                        setState(() {
                          isSearching = true;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              titleText,
                              textAlign: TextAlign.center,
                              style: titleTextStyle,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            color: Colors.black,
                            onPressed: () {
                              setState(() {
                                isSearching = true;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (isSearching && predictions.isNotEmpty)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: min(predictions.length, 5),
                  itemBuilder: (context, index) {
                    final prediction = predictions[index];
                    return ListTile(
                      title: Text(prediction.description ?? ''),
                      onTap: () async {
                        final placeId = prediction.placeId;
                        if (placeId != null) {
                          final details = await googlePlace.details.get(placeId);
                          setState(() {
                            selectedLocation = details!.result;
                            locationController.text = prediction.description!;
                            titleText = prediction.description!;
                            predictions = [];
                            isSearching = false;
                            if (selectedLocation != null &&
                                selectedLocation!.geometry != null &&
                                selectedLocation!.geometry!.location != null) {
                              searchedGeopoint = GeoPoint(
                                selectedLocation!.geometry!.location!.lat!,
                                selectedLocation!.geometry!.location!.lng!,
                              );

                              _mapController!.moveCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(
                                    searchedGeopoint!.latitude,
                                    searchedGeopoint!.longitude,
                                  ),
                                  12,
                                ),
                              );

                              _loadMarkers();
                            }
                          });
                          FocusScope.of(context).unfocus();
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          if (!primaryPage)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white.withOpacity(0.95),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Range (miles):",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Slider(
                            label: '${range.toInt()}',
                            value: range,
                            min: 1,
                            max: 20,
                            divisions: 19,
                            onChanged: (double value) {
                              setState(() {
                                range = value;
                                _loadMarkers();
                              });
                            },
                            activeColor: Colors.deepPurple,
                            inactiveColor: Colors.deepPurple[100],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              showRangeCircle = !showRangeCircle;
                              _loadMarkers();
                            });
                          },
                          child: Text(
                            showRangeCircle ? 'Hide Range' : 'Show Range',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => switchPostType(0),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedIndex == 0 ? Colors.deepPurple : Colors.grey[200],
                            ),
                            child: Text(
                              'Non-Recurring',
                              style: buttonTextStyle.copyWith(
                                color: selectedIndex == 0 ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => switchPostType(1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedIndex == 1 ? Colors.deepPurple : Colors.grey[200],
                            ),
                            child: Text(
                              'Recurring',
                              style: buttonTextStyle.copyWith(
                                color: selectedIndex == 1 ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (primaryPage)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: TextField(
                                    maxLines: null,
                                    controller: locationController,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.location_on),
                                      suffixIcon: locationController.text.isNotEmpty
                                          ? IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  predictions = [];
                                                  locationController.clear();
                                                  selectedLocation = null;
                                                });
                                              },
                                              icon: const Icon(Icons.clear_rounded),
                                            )
                                          : null,
                                      hintText: 'Enter a location',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      contentPadding: const EdgeInsets.symmetric(vertical: 20.0),
                                    ),
                                    onChanged: (text) {
                                      if (debounce?.isActive ?? false) debounce!.cancel();
                                      debounce = Timer(const Duration(milliseconds: 500), () {
                                        if (text.isNotEmpty) {
                                          showAutocomplete(text);
                                        } else {
                                          setState(() {
                                            predictions = [];
                                            selectedLocation = null;
                                          });
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (predictions.isNotEmpty)
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: min(predictions.length, 5),
                                      itemBuilder: (context, index) {
                                        final prediction = predictions[index];
                                        return Column(
                                          children: [
                                            ListTile(
                                              leading: const CircleAvatar(
                                                backgroundColor: Colors.deepPurple,
                                                child: Icon(
                                                  Icons.pin_drop_outlined,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              title: Text(
                                                prediction.description ?? '',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                              onTap: () async {
                                                final placeId = prediction.placeId;
                                                if (placeId != null) {
                                                  final details = await googlePlace.details.get(placeId);
                                                  setState(() {
                                                    selectedLocation = details!.result;
                                                    locationController.text = prediction.description!;
                                                    titleText = prediction.description!;
                                                    predictions = [];
                                                    primaryPage = false;
                                                    if (selectedLocation != null &&
                                                        selectedLocation!.geometry != null &&
                                                        selectedLocation!.geometry!.location != null) {
                                                      searchedGeopoint = GeoPoint(
                                                        selectedLocation!.geometry!.location!.lat!,
                                                        selectedLocation!.geometry!.location!.lng!,
                                                      );
                                                      _loadMarkers();
                                                    }
                                                  });
                                                  FocusScope.of(context).unfocus();
                                                }
                                              },
                                            ),
                                            const Divider(
                                              height: 1,
                                              indent: 20,
                                              endIndent: 20,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                  child: MaterialButton(
                                    onPressed: () {
                                      if (checkLocation()) {
                                        setState(() {
                                          primaryPage = false;
                                          titleText = locationController.text;
                                          _loadMarkers();
                                        });
                                      } else {
                                        showDialog(context: context, builder: (ctx) => const AlertDialog(
                                          title: Text("Choose an appropriate location"),
                                        ));
                                      }
                                    },
                                    color: Colors.deepPurple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search, color: Colors.white),
                                        SizedBox(width: 10),
                                        Text(
                                          "GO",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                child: Text(
                                  "OR",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: MaterialButton(
                              onPressed: () {
                                _getCurrentLocation();
                              },
                              color: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15.0),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.my_location, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text(
                                    "Use Current Location",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'api.dart';

// ==========================================
// DELIVERY PARTNER LOGIN
// ==========================================

class PartnerLogin extends StatefulWidget {
  const PartnerLogin({super.key});

  @override
  State<PartnerLogin> createState() => _PartnerLoginState();
}

class _PartnerLoginState extends State<PartnerLogin> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool busy = false;

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password')),
      );
      return;
    }

    setState(() => busy = true);

    try {
      final data = await Api.post('/auth/login', {
        'email': email.text.trim(),
        'password': password.text,
      });

      final role = data['user']?['role'];

      if (role != 'delivery') {
        throw Exception('This account is not a delivery partner');
      }

      await Api.saveToken(data['token']);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PartnerHome(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delivery_dining,
                size: 75,
                color: Color(0xff1565c0),
              ),
              const SizedBox(height: 12),
              const Text(
                'Delivery Partner',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : login,
                  child: Text(busy ? 'Signing in...' : 'Login'),
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
// DELIVERY PARTNER HOME
// ==========================================

class PartnerHome extends StatefulWidget {
  const PartnerHome({super.key});

  @override
  State<PartnerHome> createState() => _PartnerHomeState();
}

class _PartnerHomeState extends State<PartnerHome> {
  List orders = [];
  bool busy = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        busy = true;
        error = '';
      });
    }

    try {
      final data = await Api.get('/orders/delivery');

      if (mounted) {
        setState(() {
          orders = data['orders'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> claim(String id) async {
    try {
      await Api.post('/orders/$id/claim', {});
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> update(String id, String status) async {
    try {
      await Api.patch('/orders/$id/status', {
        'status': status,
      });
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> logout() async {
    await Api.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const PartnerLogin(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My deliveries'),
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: busy
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : orders.isEmpty
                  ? const Center(
                      child: Text('No assigned deliveries yet'),
                    )
                  : RefreshIndicator(
                      onRefresh: load,
                      child: ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];

                          final id = order['_id'].toString();
                          final status = order['status'].toString();
                          final address =
                              (order['address'] ?? '').toString();

                          final next = status == 'ready'
                              ? 'picked_up'
                              : status == 'picked_up'
                                  ? 'on_the_way'
                                  : status == 'on_the_way'
                                      ? 'delivered'
                                      : null;

                          final assigned =
                              order['deliveryPartner'] != null;

                          final shortId = id.length >= 6
                              ? id.substring(id.length - 6)
                              : id;

                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order #$shortId',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Customer: ${order['customer']?['name'] ?? 'Customer'}',
                                  ),
                                  Text(
                                    'Store: ${order['store']?['name'] ?? 'Store'}',
                                  ),
                                  Text('Delivery address: $address'),
                                  const SizedBox(height: 5),
                                  Text('Status: $status'),

                                  if (assigned &&
                                      (status == 'picked_up' ||
                                          status == 'on_the_way'))
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DeliveryMapScreen(
                                              address: address,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.map),
                                      label: const Text(
                                        'Open delivery map',
                                      ),
                                    ),

                                  if (!assigned && status == 'ready')
                                    FilledButton(
                                      onPressed: () => claim(id),
                                      child: const Text(
                                        'Accept delivery',
                                      ),
                                    ),

                                  if (assigned && next != null)
                                    FilledButton(
                                      onPressed: () => update(id, next),
                                      child: Text(
                                        next
                                            .replaceAll('_', ' ')
                                            .toUpperCase(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ==========================================
// DELIVERY MAP
// ==========================================

class DeliveryMapScreen extends StatefulWidget {
  final String address;

  const DeliveryMapScreen({
    super.key,
    required this.address,
  });

  @override
  State<DeliveryMapScreen> createState() =>
      _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  final MapController mapController = MapController();

  // Correct geocoding 5.0.1 API.
  final Geocoding geocoding = Geocoding();

  LatLng? current;
  LatLng? destination;

  List<LatLng> route = [];

  StreamSubscription<Position>? positionSub;

  String message = 'Getting your location...';

  bool loadingRoute = false;
  bool mapReady = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  // ========================================
  // GET CURRENT GPS LOCATION
  // ========================================

  Future<void> _start() async {
    try {
      final enabled =
          await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        throw Exception('Turn on Location/GPS on your phone.');
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Allow location permission for QuickDeliver in Android Settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        current = LatLng(
          position.latitude,
          position.longitude,
        );
        message = 'Finding delivery address...';
      });

      // Convert customer address to map coordinates.
      if (widget.address.trim().isEmpty) {
        setState(() {
          message = 'This order has no delivery address.';
        });
      } else {
        try {
          final found = await geocoding.locationFromAddress(
            widget.address,
          );

          if (!mounted) return;

          if (found.isNotEmpty) {
            setState(() {
              destination = LatLng(
                found.first.latitude,
                found.first.longitude,
              );
              message = '';
            });

            await _loadRoute();
            _fitMap();
          } else {
            setState(() {
              message =
                  'Could not find the delivery address on the map.';
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              message =
                  'Address lookup failed. Check the delivery address and internet connection.';
            });
          }
        }
      }

      // Listen for GPS position changes.
      positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((position) {
        if (!mounted) return;

        setState(() {
          current = LatLng(
            position.latitude,
            position.longitude,
          );
        });
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          message = e.toString().replaceFirst(
                'Exception: ',
                '',
              );
        });
      }
    }
  }

  // ========================================
  // LOAD ROUTE
  // ========================================

  Future<void> _loadRoute() async {
    if (current == null || destination == null) return;

    setState(() => loadingRoute = true);

    try {
      final start = current!;
      final end = destination!;

      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Route service unavailable');
      }

      final data = jsonDecode(response.body);

      if (data['routes'] == null ||
          (data['routes'] as List).isEmpty) {
        throw Exception('No route found');
      }

      final coordinates =
          data['routes'][0]['geometry']['coordinates'] as List;

      final points = coordinates.map<LatLng>((coordinate) {
        return LatLng(
          (coordinate[1] as num).toDouble(),
          (coordinate[0] as num).toDouble(),
        );
      }).toList();

      if (mounted) {
        setState(() {
          route = points;
          message = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          message =
              'Route unavailable. You can still see both map markers.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => loadingRoute = false);
      }
    }
  }

  // ========================================
  // FIT MAP TO BOTH LOCATIONS
  // ========================================

  void _fitMap() {
    if (current == null ||
        destination == null ||
        !mapReady) {
      return;
    }

    final bounds = LatLngBounds.fromPoints([
      current!,
      destination!,
    ]);

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(55),
      ),
    );
  }

  // ========================================
  // CENTER ON DELIVERY PARTNER
  // ========================================

  void _centerOnMe() {
    if (current != null && mapReady) {
      mapController.move(current!, 16);
    }
  }

  @override
  void dispose() {
    positionSub?.cancel();
    mapController.dispose();
    super.dispose();
  }

  // ========================================
  // MAP UI
  // ========================================

  @override
  Widget build(BuildContext context) {
    final center =
        current ?? const LatLng(12.9716, 77.5946);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery map'),
        actions: [
          IconButton(
            onPressed: () async {
              await _loadRoute();
              _fitMap();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh route',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
              onMapReady: () {
                mapReady = true;
                _fitMap();
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.quickdeliver_delivery',
              ),

              if (route.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route,
                      strokeWidth: 5,
                      color: Colors.blue,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  if (current != null)
                    Marker(
                      point: current!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.delivery_dining,
                        color: Colors.blue,
                        size: 42,
                      ),
                    ),

                  if (destination != null)
                    Marker(
                      point: destination!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 46,
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (message.isNotEmpty || loadingRoute)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (loadingRoute || current == null)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      if (loadingRoute || current == null)
                        const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message.isEmpty
                              ? 'Loading route...'
                              : message,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 18,
            right: 16,
            child: FloatingActionButton(
              onPressed: _centerOnMe,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
      bottomNavigationBar: destination == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Destination: ${widget.address}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}

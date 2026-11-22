
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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
    const blue = Color(0xFF2456C5);
    const ink = Color(0xFF17233B);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 88, width: 88,
                    decoration: BoxDecoration(color: blue.withOpacity(.10), borderRadius: BorderRadius.circular(28)),
                    child: const Icon(Icons.delivery_dining_rounded, size: 52, color: blue),
                  ),
                  const SizedBox(height: 28),
                  const Text('Your next delivery starts here.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ink, height: 1.15)),
                  const SizedBox(height: 9),
                  const Text('Sign in to manage your jobs, reach customers and keep every order moving.', style: TextStyle(color: Color(0xFF718099), fontSize: 15)),
                  const SizedBox(height: 30),
                  const Text('EMAIL ADDRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF718099))),
                  const SizedBox(height: 7),
                  TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'you@example.com')),
                  const SizedBox(height: 16),
                  const Text('PASSWORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF718099))),
                  const SizedBox(height: 7),
                  TextField(controller: password, obscureText: true, decoration: const InputDecoration(hintText: 'Enter your password')),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: busy ? null : login, child: Text(busy ? 'Signing in…' : 'Sign in')),
                  const SizedBox(height: 18),
                  const Center(child: Text('QUICKDELIVER PARTNER', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w800, color: Color(0xFF8A96AA)))),
                ],
              ),
            ),
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
  bool available = true;
  bool availabilityBusy = false;
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
      final results = await Future.wait([
        Api.get('/orders/delivery'),
        Api.get('/auth/me'),
      ]);
      final data = results[0];
      final user = results[1]['user'] ?? {};
      if (mounted) {
        setState(() {
          orders = data['orders'] ?? [];
          available = user['isAvailable'] != false;
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

  Future<void> setAvailability(bool value) async {
    if (availabilityBusy) return;
    setState(() => availabilityBusy = true);
    try {
      final result = await Api.patch('/auth/availability', {'isAvailable': value});
      if (mounted) {
        setState(() => available = result['isAvailable'] == true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(available ? 'You are available for new jobs' : 'You will not receive new jobs')),
        );
        await load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => availabilityBusy = false);
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
    final active = orders.where((o) => !['delivered','cancelled'].contains(o['status'])).length;
    final completed = orders.where((o) => o['status'] == 'delivered').toList();
    final deliveryFees = completed.fold<double>(0, (sum, order) => sum + ((order['deliveryFee'] as num?)?.toDouble() ?? 0));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner hub'),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout_rounded), tooltip: 'Log out'),
        ],
      ),
      body: busy
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error, textAlign: TextAlign.center)))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2456C5),
                          borderRadius: BorderRadius.circular(23),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('READY FOR THE ROAD?', style: TextStyle(color: Color(0xFFD4E1FF), fontSize: 10, letterSpacing: 1.3, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 9),
                            const Text('Every delivery makes a difference.', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 17),
                            Row(children: [
                              const Icon(Icons.local_shipping_outlined, color: Colors.white70, size: 19),
                              const SizedBox(width: 8),
                              Text('$active active deliveries', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: SwitchListTile(
                          value: available,
                          onChanged: availabilityBusy ? null : setAvailability,
                          secondary: Icon(available ? Icons.wifi_tethering_rounded : Icons.pause_circle_outline_rounded, color: available ? const Color(0xFF16845B) : const Color(0xFF718099)),
                          title: Text(available ? 'You are available' : 'You are unavailable', style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(available ? 'New ready orders can be claimed' : 'You can finish assigned deliveries, but cannot claim new ones'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _PartnerStatCard(label: 'Completed', value: completed.length.toString(), icon: Icons.task_alt_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _PartnerStatCard(label: 'Delivery fees', value: '₹${deliveryFees.toStringAsFixed(0)}', icon: Icons.currency_rupee_rounded)),
                      ]),
                      const SizedBox(height: 23),
                      Row(children: [
                        const Expanded(child: Text('Your deliveries', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF17233B)))),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: const Color(0xFFE7EEFF), borderRadius: BorderRadius.circular(30)), child: Text('${orders.length} orders', style: const TextStyle(color: Color(0xFF2456C5), fontSize: 11, fontWeight: FontWeight.w800))),
                      ]),
                      const SizedBox(height: 13),
                      if (orders.isEmpty)
                        const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Column(children: [
                          Icon(Icons.inventory_2_outlined, size: 54, color: Color(0xFF9AA7BB)),
                          SizedBox(height: 12),
                          Text('No deliveries available', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          SizedBox(height: 5),
                          Text('Pull down to check for new orders.', style: TextStyle(color: Color(0xFF718099))),
                        ]))
                      else
                        ...orders.map((order) {
                          final id = order['_id'].toString();
                          final status = order['status'].toString();
                          final address = (order['address'] ?? '').toString();
                          final next = status == 'ready' ? 'picked_up' : status == 'picked_up' ? 'on_the_way' : status == 'on_the_way' ? 'delivered' : null;
                          final assigned = order['deliveryPartner'] != null;
                          final shortId = id.length >= 6 ? id.substring(id.length - 6).toUpperCase() : id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(17),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(child: Text('ORDER #$shortId', style: const TextStyle(fontSize: 11, letterSpacing: 1, color: Color(0xFF718099), fontWeight: FontWeight.w800))),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFE7EEFF), borderRadius: BorderRadius.circular(30)), child: Text(status.replaceAll('_', ' '), style: const TextStyle(color: Color(0xFF2456C5), fontSize: 11, fontWeight: FontWeight.w800))),
                                    ]),
                                    const SizedBox(height: 12),
                                    Text(order['customer']?['name'] ?? 'Customer', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF17233B))),
                                    const SizedBox(height: 4),
                                    Text('Pickup · ${order['store']?['name'] ?? 'Store'}', style: const TextStyle(color: Color(0xFF718099), fontSize: 13)),
                                    const SizedBox(height: 11),
                                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Icon(Icons.location_on_outlined, color: Color(0xFF2456C5), size: 18),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(address.isEmpty ? 'Delivery address not provided' : address, style: const TextStyle(color: Color(0xFF52617A), fontSize: 13))),
                                    ]),
                                    if (assigned && (status == 'picked_up' || status == 'on_the_way')) ...[
                                      const SizedBox(height: 10),
                                      OutlinedButton.icon(
                                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeliveryMapScreen(address: address, orderId: id))),
                                        icon: const Icon(Icons.map_outlined),
                                        label: const Text('Open delivery map'),
                                      ),
                                    ],
                                    if (!assigned && status == 'ready') ...[
                                      const SizedBox(height: 14),
                                      FilledButton.icon(onPressed: () => claim(id), icon: const Icon(Icons.check_circle_outline), label: const Text('Accept delivery')),
                                    ],
                                    if (assigned && next != null) ...[
                                      const SizedBox(height: 14),
                                      FilledButton.icon(onPressed: () => update(id, next), icon: const Icon(Icons.arrow_forward_rounded), label: Text(next.replaceAll('_', ' ').toUpperCase())),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }}

// ==========================================
// DELIVERY MAP
// ==========================================

class DeliveryMapScreen extends StatefulWidget {
  final String address;
  final String orderId;

  const DeliveryMapScreen({
    super.key,
    required this.address,
    required this.orderId,
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

  Future<void> _sendLocation(double latitude, double longitude) async {
    try {
      await Api.patch('/orders/${widget.orderId}/location', {
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (_) {
      // Keep local GPS updates running through temporary network failures.
    }
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
      await _sendLocation(position.latitude, position.longitude);

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
        unawaited(_sendLocation(position.latitude, position.longitude));
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
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Destination: ${widget.address}', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: FilledButton.icon(
                  onPressed: () async {
                    final point = destination!;
                    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${point.latitude},${point.longitude}&travelmode=driving');
                    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
                    if (!opened && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Google Maps.')));
                    }
                  },
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('Start turn-by-turn navigation'),
                ),
              ),
            ),
    );
  }
}


// ==========================================
// PARTNER DASHBOARD STAT CARD
// ==========================================

class _PartnerStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PartnerStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2456C5), size: 22),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17233B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF718099),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

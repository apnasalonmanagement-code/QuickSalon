import 'package:flutter/material.dart';

import '../../core/constants/shop_constants.dart';
import '../../core/services/location_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/cloudinary_service.dart';
import 'salon_controller.dart';

class EditSalonScreen extends StatefulWidget {
  const EditSalonScreen({
    super.key,
    required this.initial,
  });

  final Map<String, dynamic> initial;

  @override
  State<EditSalonScreen> createState() =>
      _EditSalonScreenState();
}

class _EditSalonScreenState
    extends State<EditSalonScreen> {
  late final TextEditingController
      name,
      city,
      phone,
      location,
      latitude,
      longitude,
      description,
      image;

  String shopType = 'salon';

  TimeOfDay? opening;
  TimeOfDay? closing;

  bool status = true;
  bool uploading = false;
  bool gettingLocation = false;

  final CloudinaryService cloudinary =
      const CloudinaryService();

  final SalonController controller =
      SalonController();

  final LocationService _locationService =
      const LocationService();

  @override
  void initState() {
    super.initState();

    final s = widget.initial;

    name = TextEditingController(
      text: s['shop_name']?.toString() ?? '',
    );

    city = TextEditingController(
      text: s['city']?.toString() ?? '',
    );

    phone = TextEditingController(
      text: s['phone']?.toString() ?? '',
    );

    location = TextEditingController(
      text: s['location_url']?.toString() ?? '',
    );

    latitude = TextEditingController(
      text: s['latitude']?.toString() ?? '',
    );

    longitude = TextEditingController(
      text: s['longitude']?.toString() ?? '',
    );

    description = TextEditingController(
      text: s['description']?.toString() ?? '',
    );

    image = TextEditingController(
      text: s['image_url']?.toString() ?? '',
    );

    status = s['status'] as bool? ?? true;

    final storedType =
        s['shop_type']?.toString();

    if (ShopConstants.shopTypes
        .contains(storedType)) {
      shopType = storedType!;
    }

    opening =
        _parse(s['opening_time']);

    closing =
        _parse(s['closing_time']);
  }

  @override
  void dispose() {
    for (final c in [
      name,
      city,
      phone,
      location,
      latitude,
      longitude,
      description,
      image,
    ]) {
      c.dispose();
    }

    controller.dispose();

    super.dispose();
  }

  TimeOfDay? _parse(dynamic v) {
    if (v == null) {
      return null;
    }

    final p =
        v.toString().split(':');

    if (p.length < 2) {
      return null;
    }

    return TimeOfDay(
      hour:
          int.tryParse(p[0]) ?? 0,
      minute:
          int.tryParse(p[1]) ?? 0,
    );
  }

  String _time(TimeOfDay? t) =>
      t == null
          ? ''
          : '${t.hour.toString().padLeft(2, '0')}:'
            '${t.minute.toString().padLeft(2, '0')}:00';

  // ============================================================
  // GET CURRENT SHOP LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    if (gettingLocation) {
      return;
    }

    setState(() {
      gettingLocation = true;
    });

    try {
      final position =
          await _locationService
              .getCurrentLocation();

      latitude.text =
          position.latitude
              .toStringAsFixed(8);

      longitude.text =
          position.longitude
              .toStringAsFixed(8);

      _msg(
        'Shop location captured successfully.',
      );
    } catch (e) {
      _msg(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          gettingLocation = false;
        });
      }
    }
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<void> _pickImage() async {
    final file =
        await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (file == null) {
      return;
    }

    if (!cloudinary.isConfigured) {
      _msg(
        'Cloudinary is not configured. '
        'You can enter an image URL manually.',
      );
      return;
    }

    setState(() {
      uploading = true;
    });

    try {
      final url =
          await cloudinary
              .uploadShopImage(file);

      if (url != null) {
        image.text = url;
      }
    } catch (e) {
      if (mounted) {
        _msg(
          e.toString().replaceFirst(
                'Exception: ',
                '',
              ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          uploading = false;
        });
      }
    }
  }

  // ============================================================
  // TIME PICKER
  // ============================================================

  Future<void> _timePicker(
    bool isOpening,
  ) async {
    final picked =
        await showTimePicker(
      context: context,
      initialTime:
          (isOpening
                  ? opening
                  : closing) ??
              TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          opening = picked;
        } else {
          closing = picked;
        }
      });
    }
  }

  // ============================================================
  // SAVE SHOP
  // ============================================================

  Future<void> _save() async {
    if (name.text.trim().isEmpty ||
        city.text.trim().isEmpty) {
      _msg(
        'Shop name and city are required.',
      );
      return;
    }

    if (opening != null &&
        closing != null &&
        _minutes(closing!) <=
            _minutes(opening!)) {
      _msg(
        'Closing time must be after opening time.',
      );
      return;
    }

    // ------------------------------------------------------------
    // VALIDATE LATITUDE / LONGITUDE
    // ------------------------------------------------------------

    final lat =
        double.tryParse(
      latitude.text.trim(),
    );

    final lng =
        double.tryParse(
      longitude.text.trim(),
    );

    if (lat == null || lng == null) {
      _msg(
        'Please enter or capture a valid latitude and longitude.',
      );
      return;
    }

    if (lat < -90 || lat > 90) {
      _msg(
        'Latitude must be between -90 and 90.',
      );
      return;
    }

    if (lng < -180 || lng > 180) {
      _msg(
        'Longitude must be between -180 and 180.',
      );
      return;
    }

    // ------------------------------------------------------------
    // SAVE
    // ------------------------------------------------------------

    final ok =
        await controller.save({
      'shop_name':
          name.text.trim(),

      'city':
          city.text.trim(),

      'shop_type':
          shopType,

      'phone':
          phone.text.trim().isEmpty
              ? null
              : phone.text.trim(),

      // Existing Google Maps URL
      'location_url':
          location.text.trim().isEmpty
              ? null
              : location.text.trim(),

      // NEW GPS COORDINATES
      'latitude':
          lat,

      'longitude':
          lng,

      'description':
          description.text.trim().isEmpty
              ? null
              : description.text.trim(),

      'image_url':
          image.text.trim().isEmpty
              ? null
              : image.text.trim(),

      'opening_time':
          opening == null
              ? null
              : _time(opening),

      'closing_time':
          closing == null
              ? null
              : _time(closing),

      'status':
          status,

      'updated_at':
          DateTime.now()
              .toUtc()
              .toIso8601String(),
    });

    if (ok && mounted) {
      Navigator.pop(
        context,
        true,
      );
    } else if (controller.errorMessage != null) {
      _msg(
        controller.errorMessage!,
      );
    }
  }

  int _minutes(TimeOfDay t) =>
      t.hour * 60 + t.minute;

  // ============================================================
  // MESSAGE
  // ============================================================

  void _msg(String m) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
        content: Text(
          m,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final primaryColor =
        Theme.of(context)
            .colorScheme
            .primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Shop',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          // ======================================================
          // SHOP NAME
          // ======================================================

          TextField(
            controller: name,
            decoration:
                InputDecoration(
              labelText:
                  'Shop name',
              border:
                  const OutlineInputBorder(),
              focusedBorder:
                  OutlineInputBorder(
                borderSide:
                    BorderSide(
                  color:
                      primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ======================================================
          // CITY
          // ======================================================

          DropdownButtonFormField<
              String>(
            value:
                ShopConstants
                    .canonicalCity(
              city.text,
            ),
            decoration:
                InputDecoration(
              labelText:
                  'City',
              border:
                  const OutlineInputBorder(),
              focusedBorder:
                  OutlineInputBorder(
                borderSide:
                    BorderSide(
                  color:
                      primaryColor,
                  width: 2,
                ),
              ),
            ),
            items:
                ShopConstants
                    .supportedCities
                    .map(
              (
                value,
              ) =>
                  DropdownMenuItem<
                      String>(
                value:
                    value,
                child:
                    Text(value),
              ),
            ).toList(),
            onChanged:
                (value) {
              if (value !=
                  null) {
                city.text =
                    value;
              }
            },
          ),

          const SizedBox(
            height: 16,
          ),

          // ======================================================
          // SHOP TYPE
          // ======================================================

          DropdownButtonFormField<
              String>(
            value:
                shopType,
            decoration:
                InputDecoration(
              labelText:
                  'Shop type',
              border:
                  const OutlineInputBorder(),
              focusedBorder:
                  OutlineInputBorder(
                borderSide:
                    BorderSide(
                  color:
                      primaryColor,
                  width: 2,
                ),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value:
                    'salon',
                child:
                    Text('Salon'),
              ),
              DropdownMenuItem(
                value:
                    'parlour',
                child:
                    Text('Parlour'),
              ),
              DropdownMenuItem(
                value:
                    'unisexsalon',
                child:
                    Text(
                  'Unisex Salon',
                ),
              ),
            ],
            onChanged:
                (value) {
              if (value !=
                  null) {
                setState(() {
                  shopType =
                      value;
                });
              }
            },
          ),

          const SizedBox(
            height: 16,
          ),

          // ======================================================
          // PHONE
          // ======================================================

          TextField(
            controller:
                phone,
            keyboardType:
                TextInputType.phone,
            decoration:
                InputDecoration(
              labelText:
                  'Phone',
              border:
                  const OutlineInputBorder(),
              focusedBorder:
                  OutlineInputBorder(
                borderSide:
                    BorderSide(
                  color:
                      primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ======================================================
          // GOOGLE MAPS URL
          // ======================================================

          TextField(
            controller:
                location,
            decoration:
                InputDecoration(
              labelText:
                  'Location URL',
              border:
                  const OutlineInputBorder(),
              focusedBorder:
                  OutlineInputBorder(
                borderSide:
                    BorderSide(
                  color:
                      primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ======================================================
          // LATITUDE
          // ======================================================

          TextField(
            controller:
                latitude,
            keyboardType:
                const TextInputType
                    .numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration:
                InputDecoration(
              labelText:
                  'Latitude',
              hintText:
                  'Example: 17.6850',
              prefixIcon:
                  const Icon(
                Icons
                    .explore_outlined,
              ),
              border:
                  const OutlineInputBorder(),
              focusedBorder:
                  OutlineInputBorder(
                borderSide:
                    BorderSide(
                  color:
                      primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ======================================================
          // LONGITUDE
          // ======================================================

          TextField(
            controller:
                longitude,
            keyboardType:
                const TextInputType
                    .numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration:
                InputDecoration(
              labelText:
                  'Longitude',
              hintText:
                  'Example: 74.0183',
              prefixIcon:
                  const Icon(
                Icons
                    .explore_outlined,
              ),
              border:
                  const OutlineInputBorder(),
              focusedBorder:
                  OutlineInputBorder(
                borderSide:
                    BorderSide(
                  color:
                      primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ======================================================
          // GET CURRENT LOCATION
          // ======================================================

          OutlinedButton.icon(
            onPressed:
                gettingLocation
                    ? null
                    : _getCurrentLocation,
            icon:
                gettingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      )
                    : const Icon(
                        Icons
                            .my_location,
                      ),
            label:
                Text(
              gettingLocation
                  ? 'Getting Location...'
                  : 'Get Current Location',
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ======================================================
          // DESCRIPTION
          // ======================================================

          TextField(
            controller:
                description,
            maxLines: 3,
            decoration:
                InputDecoration(
              labelText:
                  'Description',
              border:
                  const OutlineInputBorder(),
              focusedBorder:
                  OutlineInputBorder(
                borderSide:
                    BorderSide(
                  color:
                      primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ======================================================
          // IMAGE URL + CLOUDINARY
          // ======================================================

          Row(
            children: [
              Expanded(
                child:
                    TextField(
                  controller:
                      image,
                  decoration:
                      InputDecoration(
                    labelText:
                        'Image URL',
                    border:
                        const OutlineInputBorder(),
                    focusedBorder:
                        OutlineInputBorder(
                      borderSide:
                          BorderSide(
                        color:
                            primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              IconButton
                  .filledTonal(
                onPressed:
                    uploading
                        ? null
                        : _pickImage,
                icon:
                    uploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
                            Icons
                                .cloud_upload_outlined,
                          ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          // ======================================================
          // OPENING / CLOSING TIME
          // ======================================================

          Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              side:
                  BorderSide(
                color:
                    Colors.grey.shade300,
              ),
            ),
            child:
                Column(
              children: [
                ListTile(
                  leading:
                      Icon(
                    Icons.schedule,
                    color:
                        primaryColor,
                  ),
                  title:
                      const Text(
                    'Opening time',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  subtitle:
                      Text(
                    opening?.format(
                          context,
                        ) ??
                        'Not set',
                  ),
                  onTap:
                      () =>
                          _timePicker(
                    true,
                  ),
                ),

                const Divider(
                  height: 1,
                ),

                ListTile(
                  leading:
                      Icon(
                    Icons
                        .schedule_outlined,
                    color:
                        primaryColor,
                  ),
                  title:
                      const Text(
                    'Closing time',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  subtitle:
                      Text(
                    closing?.format(
                          context,
                        ) ??
                        'Not set',
                  ),
                  onTap:
                      () =>
                          _timePicker(
                    false,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          // ======================================================
          // SHOP STATUS
          // ======================================================

          Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              side:
                  BorderSide(
                color:
                    Colors.grey.shade300,
              ),
            ),
            child:
                SwitchListTile(
              secondary:
                  Icon(
                Icons.storefront,
                color:
                    primaryColor,
              ),
              title:
                  const Text(
                'Shop active',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              value:
                  status,
              onChanged:
                  (v) =>
                      setState(
                () {
                  status = v;
                },
              ),
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // ======================================================
          // SAVE BUTTON
          // ======================================================

          FilledButton(
            style:
                FilledButton.styleFrom(
              backgroundColor:
                  primaryColor,
              minimumSize:
                  const Size(
                double.infinity,
                50,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
            ),
            onPressed:
                controller.isSaving
                    ? null
                    : _save,
            child:
                controller.isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize:
                              16,
                        ),
                      ),
          ),

          const SizedBox(
            height: 16,
          ),
        ],
      ),
    );
  }
}
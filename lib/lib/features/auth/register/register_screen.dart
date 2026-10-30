import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/shop_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/services/location_service.dart';
import '../../../app/theme.dart';
import 'register_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final _formKey =
      GlobalKey<FormState>();

  // Owner fields
  final _nameController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _phoneController =
      TextEditingController();

  final _cityController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  // Shop fields
  final _shopNameController =
      TextEditingController();

  final _shopPhoneController =
      TextEditingController();

  final _shopCityController =
      TextEditingController();

  final _locationUrlController =
      TextEditingController();

  final _latitudeController =
      TextEditingController();

  final _longitudeController =
      TextEditingController();

  final _locationController =
      TextEditingController();

  final _descriptionController =
      TextEditingController();

  final LocationService _locationService =
      const LocationService();

  bool _gettingLocation = false;

  DateTime? _dob;

  TimeOfDay? _openingTime;

  TimeOfDay? _closingTime;

  bool _obscurePassword = true;

  bool _obscureConfirmPassword = true;

  String? _shopType = 'salon';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _shopNameController.dispose();
    _shopPhoneController.dispose();
    _shopCityController.dispose();
    _locationUrlController.dispose();

    _latitudeController.dispose();
    _longitudeController.dispose();
    _locationController.dispose();

    _descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    if (_gettingLocation) return;

    setState(() {
      _gettingLocation = true;
    });

    try {
      final position =
          await _locationService.getCurrentLocation();

      final latitude =
          position.latitude;

      final longitude =
          position.longitude;

      _latitudeController.text =
          latitude.toStringAsFixed(8);

      _longitudeController.text =
          longitude.toStringAsFixed(8);

      _locationController.text =
          '${latitude.toStringAsFixed(6)}, '
          '${longitude.toStringAsFixed(6)}';

      _showMessage(
        'Location captured successfully.',
      );

      if (mounted) {
        _formKey.currentState?.validate();
      }
    } catch (e) {
      final message =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      _showMessage(message);
    } finally {
      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDob() async {
    final now = DateTime.now();

    final selected =
        await showDatePicker(
      context: context,
      initialDate: DateTime(
        now.year - 25,
        now.month,
        now.day,
      ),
      firstDate: DateTime(1940),
      lastDate: now,
    );

    if (selected != null) {
      setState(() {
        _dob = selected;
      });
    }
  }

  // ============================================================
  // TIME PICKER
  // ============================================================

  Future<void> _selectOpeningTime() async {
    final selected =
        await showTimePicker(
      context: context,
      initialTime:
          const TimeOfDay(
        hour: 9,
        minute: 0,
      ),
    );

    if (selected != null) {
      setState(() {
        _openingTime = selected;
      });
    }
  }

  Future<void> _selectClosingTime() async {
    final selected =
        await showTimePicker(
      context: context,
      initialTime:
          const TimeOfDay(
        hour: 20,
        minute: 0,
      ),
    );

    if (selected != null) {
      setState(() {
        _closingTime = selected;
      });
    }
  }

  // ============================================================
  // TIME FORMAT
  // ============================================================

  String? _formatTime(
    TimeOfDay? time,
  ) {
    if (time == null) {
      return null;
    }

    final hour =
        time.hour.toString().padLeft(2, '0');

    final minute =
        time.minute.toString().padLeft(2, '0');

    return '$hour:$minute:00';
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dob == null) {
      _showMessage(
        'Please select your date of birth.',
      );

      return;
    }

    if (_openingTime == null) {
      _showMessage(
        'Please select shop opening time.',
      );

      return;
    }

    if (_closingTime == null) {
      _showMessage(
        'Please select shop closing time.',
      );

      return;
    }

    final openingMinutes =
        _openingTime!.hour * 60 +
            _openingTime!.minute;

    final closingMinutes =
        _closingTime!.hour * 60 +
            _closingTime!.minute;

    if (closingMinutes <= openingMinutes) {
      _showMessage(
        'Closing time must be after opening time.',
      );

      return;
    }

    final latitude =
        double.tryParse(
      _latitudeController.text.trim(),
    );

    final longitude =
        double.tryParse(
      _longitudeController.text.trim(),
    );

    if (latitude == null ||
        longitude == null) {
      _showMessage(
        'Please capture shop location.',
      );

      return;
    }

    final controller =
        context.read<RegisterController>();

    final success =
        await controller.registerOwner(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      city: _cityController.text,
      dob: _dob!,
      password: _passwordController.text,
      shopName: _shopNameController.text,
      shopPhone: _shopPhoneController.text,
      shopCity: _shopCityController.text,
      shopType: _shopType!,
      locationUrl:
          _locationUrlController.text,

      latitude:
          double.tryParse(
        _latitudeController.text,
      ),

      longitude:
          double.tryParse(
        _longitudeController.text,
      ),

      description:
          _descriptionController.text,
      openingTime:
          _formatTime(_openingTime),
      closingTime:
          _formatTime(_closingTime),
    );

    if (!mounted) return;

    if (success) {
      _showMessage(
        'Account and shop created successfully.',
      );

      Navigator.pushReplacementNamed(
        context,
        '/home',
      );
    } else {
      _showMessage(
        controller.errorMessage ??
            'Registration failed.',
      );
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // REQUIRED FIELD
  // ============================================================

  String? _required(
    String? value,
    String field,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return '$field is required.';
    }

    return null;
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final themeNotifier =
        context.watch<ThemeNotifier>();

    final isBoy =
        themeNotifier.currentTheme ==
            SalonGenderTheme.boy;

    final primaryColor =
        Theme.of(context)
            .colorScheme
            .primary;

    return Consumer<RegisterController>(
      builder: (
        context,
        controller,
        _,
      ) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Create Owner Account',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            actions: [
              // Quick Theme Switcher in Appbar
              Padding(
                padding:
                    const EdgeInsets.only(
                  right: 16.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.boy,
                        color: isBoy
                            ? Colors.white
                            : Colors.white70,
                        size: 28,
                      ),
                      onPressed: () =>
                          themeNotifier.setTheme(
                        SalonGenderTheme.boy,
                      ),
                      tooltip:
                          'Blue Boy Theme',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.girl,
                        color: !isBoy
                            ? Colors.white
                            : Colors.white70,
                        size: 28,
                      ),
                      onPressed: () =>
                          themeNotifier.setTheme(
                        SalonGenderTheme.girl,
                      ),
                      tooltip:
                          'Pink Girl Theme',
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Container(
            decoration:
                BoxDecoration(
              gradient:
                  LinearGradient(
                colors: isBoy
                    ? [
                        const Color(
                          0xFFF0F8FF,
                        ),
                        Colors.white,
                      ]
                    : [
                        const Color(
                          0xFFFFF0F5,
                        ),
                        Colors.white,
                      ],
                begin:
                    Alignment.topCenter,
                end:
                    Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 700,
                  ),
                  child: Card(
                    margin:
                        const EdgeInsets.all(
                      16,
                    ),
                    elevation: 6,
                    shadowColor:
                        primaryColor
                            .withOpacity(
                      0.3,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        24.0,
                      ),
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          shrinkWrap: true,
                          padding:
                              const EdgeInsets.all(
                            8,
                          ),
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color:
                                      primaryColor,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  'Owner Details',
                                  style:
                                      Theme.of(
                                    context,
                                  )
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            color:
                                                primaryColor,
                                          ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            TextFormField(
                              controller:
                                  _nameController,
                              textCapitalization:
                                  TextCapitalization
                                      .words,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Full Name',
                                prefixIcon:
                                    Icon(
                                  Icons
                                      .person_outline,
                                ),
                                border:
                                    OutlineInputBorder(),
                              ),
                              validator:
                                  (value) =>
                                      _required(
                                value,
                                'Name',
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            TextFormField(
                              controller:
                                  _emailController,
                              keyboardType:
                                  TextInputType
                                      .emailAddress,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Email',
                                prefixIcon:
                                    Icon(
                                  Icons
                                      .email_outlined,
                                ),
                                border:
                                    OutlineInputBorder(),
                              ),
                              validator: AppValidators.email,
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            TextFormField(
                              controller:
                                  _phoneController,
                              keyboardType:
                                  TextInputType
                                      .phone,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Phone',
                                prefixIcon:
                                    Icon(
                                  Icons
                                      .phone_outlined,
                                ),
                                border:
                                    OutlineInputBorder(),
                              ),
                              maxLength: 10,
                              validator: AppValidators.phone,
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            DropdownButtonFormField<
                                String>(
                              value: _cityController
                                      .text
                                      .isEmpty
                                  ? null
                                  : _cityController
                                      .text,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'City',
                                prefixIcon:
                                    Icon(
                                  Icons
                                      .location_city,
                                ),
                                border:
                                    OutlineInputBorder(),
                              ),
                              items: ShopConstants
                                  .supportedCities
                                  .map(
                                (
                                  city,
                                ) =>
                                    DropdownMenuItem<
                                        String>(
                                  value:
                                      city,
                                  child:
                                      Text(
                                    city,
                                  ),
                                ),
                              ).toList(),
                              onChanged:
                                  (value) {
                                _cityController
                                        .text =
                                    value ??
                                        '';
                              },
                              validator:
                                  (value) =>
                                      _required(
                                value,
                                'City',
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            // DOB
                            InkWell(
                              onTap:
                                  _selectDob,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              child:
                                  InputDecorator(
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Date of Birth',
                                  prefixIcon:
                                      Icon(
                                    Icons
                                        .calendar_today,
                                  ),
                                  border:
                                      OutlineInputBorder(),
                                ),
                                child: Text(
                                  _dob == null
                                      ? 'Select date'
                                      : '${_dob!.day.toString().padLeft(2, '0')}/'
                                          '${_dob!.month.toString().padLeft(2, '0')}/'
                                          '${_dob!.year}',
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            TextFormField(
                              controller:
                                  _passwordController,
                              obscureText:
                                  _obscurePassword,
                              decoration:
                                  InputDecoration(
                                labelText:
                                    'Password',
                                prefixIcon:
                                    const Icon(
                                  Icons
                                      .lock_outline,
                                ),
                                suffixIcon:
                                    IconButton(
                                  onPressed:
                                      () {
                                    setState(
                                      () {
                                        _obscurePassword =
                                            !_obscurePassword;
                                      },
                                    );
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons
                                            .visibility_outlined
                                        : Icons
                                            .visibility_off_outlined,
                                  ),
                                ),
                                border:
                                    const OutlineInputBorder(),
                              ),
                              validator: AppValidators.password,
                              onChanged: (_) => setState(() {}),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text('Password requirements: at least 8 characters, uppercase, lowercase, number and special character.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ),

                            TextFormField(
                              controller:
                                  _confirmPasswordController,
                              obscureText:
                                  _obscureConfirmPassword,
                              decoration:
                                  InputDecoration(
                                labelText:
                                    'Confirm Password',
                                prefixIcon:
                                    const Icon(
                                  Icons
                                      .lock_outline,
                                ),
                                suffixIcon:
                                    IconButton(
                                  onPressed:
                                      () {
                                    setState(
                                      () {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      },
                                    );
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons
                                            .visibility_outlined
                                        : Icons
                                            .visibility_off_outlined,
                                  ),
                                ),
                                border:
                                    const OutlineInputBorder(),
                              ),
                              validator:
                                  (value) {
                                if (value ==
                                        null ||
                                    value
                                        .isEmpty) {
                                  return 'Confirm your password.';
                                }

                                if (value !=
                                    _passwordController
                                        .text) {
                                  return 'Passwords do not match.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                              height: 30,
                            ),

                            // ------------------------------------------------
                            // SHOP
                            // ------------------------------------------------

                            Row(
                              children: [
                                Icon(
                                  Icons.store,
                                  color:
                                      primaryColor,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  'Shop Details',
                                  style:
                                      Theme.of(
                                    context,
                                  )
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            color:
                                                primaryColor,
                                          ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            TextFormField(
                              controller:
                                  _shopNameController,
                              textCapitalization:
                                  TextCapitalization
                                      .words,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Shop Name',
                                prefixIcon:
                                    Icon(
                                  Icons
                                      .store_outlined,
                                ),
                                border:
                                    OutlineInputBorder(),
                              ),
                              validator:
                                  (value) =>
                                      _required(
                                value,
                                'Shop name',
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            TextFormField(
                              controller:
                                  _shopPhoneController,
                              maxLength: 10,
                              validator: (value) => AppValidators.phone(value, required: false),
                              keyboardType:
                                  TextInputType
                                      .phone,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Shop Phone',
                                prefixIcon:
                                    Icon(
                                  Icons
                                      .phone_outlined,
                                ),
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            DropdownButtonFormField<
                                String>(
                              value:
                                  _shopCityController
                                          .text
                                          .isEmpty
                                      ? null
                                      : _shopCityController
                                          .text,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Shop City',
                                prefixIcon:
                                    Icon(
                                  Icons
                                      .location_city,
                                ),
                                border:
                                    OutlineInputBorder(),
                              ),
                              items: ShopConstants
                                  .supportedCities
                                  .map(
                                (
                                  city,
                                ) =>
                                    DropdownMenuItem<
                                        String>(
                                  value:
                                      city,
                                  child:
                                      Text(
                                    city,
                                  ),
                                ),
                              ).toList(),
                              onChanged:
                                  (value) {
                                _shopCityController
                                        .text =
                                    value ??
                                        '';
                              },
                              validator:
                                  (value) =>
                                      _required(
                                value,
                                'Shop city',
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            // ------------------------------------------------
                            // SHOP LOCATION
                            // ------------------------------------------------

                            TextFormField(
                              controller:
                                  _locationController,
                              readOnly: true,
                              decoration:
                                  InputDecoration(
                                labelText:
                                    'Shop Location',
                                hintText:
                                    'Tap Get Location to capture shop location',
                                prefixIcon:
                                    const Icon(
                                  Icons
                                      .location_on_outlined,
                                ),
                                suffixIcon:
                                    _gettingLocation
                                        ? const Padding(
                                            padding:
                                                EdgeInsets.all(
                                              12,
                                            ),
                                            child:
                                                SizedBox(
                                              width:
                                                  20,
                                              height:
                                                  20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth:
                                                    2,
                                              ),
                                            ),
                                          )
                                        : IconButton(
                                            tooltip:
                                                'Get current location',
                                            onPressed:
                                                _getCurrentLocation,
                                            icon:
                                                const Icon(
                                              Icons
                                                  .my_location,
                                            ),
                                          ),
                                border:
                                    const OutlineInputBorder(),
                              ),
                              validator:
                                  (value) {
                                if (_latitudeController
                                        .text
                                        .trim()
                                        .isEmpty ||
                                    _longitudeController
                                        .text
                                        .trim()
                                        .isEmpty) {
                                  return 'Please capture shop location.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            OutlinedButton
                                .icon(
                              onPressed:
                                  _gettingLocation
                                      ? null
                                      : _getCurrentLocation,
                              icon: _gettingLocation
                                  ? const SizedBox(
                                      width:
                                          18,
                                      height:
                                          18,
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
                              label: Text(
                                _gettingLocation
                                    ? 'Getting Location...'
                                    : 'Get Current Location',
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            Text(
                              'Make sure you are physically at the shop before capturing the location.',
                              style:
                                  TextStyle(
                                fontSize: 12,
                                color: Colors
                                    .grey
                                    .shade600,
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            // ------------------------------------------------
                            // LOCATION URL
                            // ------------------------------------------------

                            TextFormField(
                              controller:
                                  _locationUrlController,
                              keyboardType:
                                  TextInputType
                                      .url,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Location URL',
                                prefixIcon:
                                    Icon(
                                  Icons
                                      .location_on_outlined,
                                ),
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            TextFormField(
                              controller:
                                  _descriptionController,
                              maxLines: 3,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Shop Description',
                                prefixIcon:
                                    Icon(
                                  Icons
                                      .description_outlined,
                                ),
                                border:
                                    OutlineInputBorder(),
                                alignLabelWithHint:
                                    true,
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            // Opening time
                            InkWell(
                              onTap:
                                  _selectOpeningTime,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              child:
                                  InputDecorator(
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Opening Time',
                                  prefixIcon:
                                      Icon(
                                    Icons
                                        .access_time,
                                  ),
                                  border:
                                      OutlineInputBorder(),
                                ),
                                child: Text(
                                  _openingTime ==
                                          null
                                      ? 'Select opening time'
                                      : _openingTime!
                                          .format(
                                          context,
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            // Closing time
                            InkWell(
                              onTap:
                                  _selectClosingTime,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              child:
                                  InputDecorator(
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Closing Time',
                                  prefixIcon:
                                      Icon(
                                    Icons
                                        .access_time,
                                  ),
                                  border:
                                      OutlineInputBorder(),
                                ),
                                child: Text(
                                  _closingTime ==
                                          null
                                      ? 'Select closing time'
                                      : _closingTime!
                                          .format(
                                          context,
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 30,
                            ),

                            SizedBox(
                              height: 52,
                              child:
                                  FilledButton(
                                style:
                                    FilledButton
                                        .styleFrom(
                                  backgroundColor:
                                      primaryColor,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      14,
                                    ),
                                  ),
                                ),
                                onPressed:
                                    controller
                                            .isLoading
                                        ? null
                                        : _register,
                                child:
                                    controller
                                            .isLoading
                                        ? const SizedBox(
                                            width:
                                                22,
                                            height:
                                                22,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth:
                                                  2,
                                              color: Colors
                                                  .white,
                                            ),
                                          )
                                        : const Text(
                                            'CREATE ACCOUNT',
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  16,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              letterSpacing:
                                                  1,
                                            ),
                                          ),
                              ),
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            TextButton(
                              onPressed:
                                  controller
                                          .isLoading
                                      ? null
                                      : () {
                                          Navigator
                                              .pop(
                                            context,
                                          );
                                        },
                              child: Text(
                                'Already have an account? Login',
                                style:
                                    TextStyle(
                                  color:
                                      primaryColor,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

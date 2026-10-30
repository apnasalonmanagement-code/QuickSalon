import 'package:flutter/material.dart';

import 'salon_controller.dart';
import 'edit_salon_screen.dart';

class SalonProfileScreen extends StatefulWidget {
  const SalonProfileScreen({
    super.key,
  });

  @override
  State<SalonProfileScreen> createState() =>
      _SalonProfileScreenState();
}

class _SalonProfileScreenState
    extends State<SalonProfileScreen> {
  late final SalonController c;

  @override
  void initState() {
    super.initState();

    c = SalonController()
      ..addListener(_refresh)
      ..load();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    c.removeListener(_refresh);
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = c.shop;

    final primaryColor =
        Theme.of(context)
            .colorScheme
            .primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shop Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Shop',
            onPressed:
                s == null
                    ? null
                    : _edit,
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
        ],
      ),

      body: c.isLoading
          ? Center(
              child:
                  CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : s == null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      24,
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 64,
                          color:
                              Colors.grey.shade400,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Text(
                          c.errorMessage ??
                              'Shop information unavailable.',
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        FilledButton(
                          style:
                              FilledButton.styleFrom(
                            backgroundColor:
                                primaryColor,
                          ),
                          onPressed:
                              c.load,
                          child:
                              const Text(
                            'Retry',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: primaryColor,
                  onRefresh: c.load,
                  child: ListView(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    children: [
                      // =====================================================
                      // SHOP IMAGE
                      // =====================================================

                      if ((s['image_url'] ?? '')
                          .toString()
                          .isNotEmpty)
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                          child:
                              Image.network(
                            s['image_url']
                                .toString(),
                            height: 200,
                            width:
                                double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                              _,
                              __,
                              ___,
                            ) =>
                                    _placeholder(),
                          ),
                        )
                      else
                        _placeholder(),

                      const SizedBox(
                        height: 20,
                      ),

                      // =====================================================
                      // SHOP NAME
                      // =====================================================

                      Text(
                        s['shop_name']
                                ?.toString() ??
                            '',
                        style:
                            Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      // =====================================================
                      // CITY + STATUS
                      // =====================================================

                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color:
                                primaryColor,
                          ),

                          const SizedBox(
                            width: 4,
                          ),

                          Text(
                            s['city'] ?? '',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Colors.grey.shade700,
                            ),
                          ),

                          const Text(
                            ' • ',
                          ),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  (s['status'] ==
                                          true
                                      ? Colors
                                          .green
                                      : Colors
                                          .red)
                                      .withOpacity(
                                0.12,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                8,
                              ),
                            ),
                            child: Text(
                              s['status'] == true
                                  ? 'Active'
                                  : 'Inactive',
                              style:
                                  TextStyle(
                                fontSize:
                                    12,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color:
                                    s['status'] ==
                                            true
                                        ? Colors
                                            .green
                                            .shade700
                                        : Colors
                                            .red
                                            .shade700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(
                        height: 32,
                      ),

                      // =====================================================
                      // SHOP INFORMATION CARD
                      // =====================================================

                      Card(
                        elevation: 1,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 8,
                          ),
                          child: Column(
                            children: [
                              // -------------------------------------------------
                              // PHONE
                              // -------------------------------------------------

                              _row(
                                Icons.phone,
                                'Phone',
                                s['phone'],
                                primaryColor,
                              ),

                              // -------------------------------------------------
                              // CITY
                              // -------------------------------------------------

                              _row(
                                Icons.location_city,
                                'City',
                                s['city'],
                                primaryColor,
                              ),

                              // -------------------------------------------------
                              // SHOP TYPE
                              // -------------------------------------------------

                              _row(
                                Icons.storefront_outlined,
                                'Shop Type',
                                _formatShopType(
                                  s['shop_type'],
                                ),
                                primaryColor,
                              ),

                              // -------------------------------------------------
                              // GOOGLE MAPS URL
                              // -------------------------------------------------

                              _row(
                                Icons.link,
                                'Location URL',
                                s['location_url'],
                                primaryColor,
                              ),

                              // -------------------------------------------------
                              // NEW: LATITUDE
                              // -------------------------------------------------

                              _row(
                                Icons.location_on_outlined,
                                'Latitude',
                                s['latitude'],
                                primaryColor,
                              ),

                              // -------------------------------------------------
                              // NEW: LONGITUDE
                              // -------------------------------------------------

                              _row(
                                Icons.location_on_outlined,
                                'Longitude',
                                s['longitude'],
                                primaryColor,
                              ),

                              // -------------------------------------------------
                              // DESCRIPTION
                              // -------------------------------------------------

                              _row(
                                Icons.description_outlined,
                                'Description',
                                s['description'],
                                primaryColor,
                              ),

                              // -------------------------------------------------
                              // OPENING TIME
                              // -------------------------------------------------

                              _row(
                                Icons.schedule,
                                'Opening Time',
                                s['opening_time'],
                                primaryColor,
                              ),

                              // -------------------------------------------------
                              // CLOSING TIME
                              // -------------------------------------------------

                              _row(
                                Icons.schedule_outlined,
                                'Closing Time',
                                s['closing_time'],
                                primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // =====================================================
                      // EDIT SHOP PROFILE BUTTON
                      // =====================================================

                      FilledButton.icon(
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
                            _edit,
                        icon:
                            const Icon(
                          Icons.edit,
                        ),
                        label:
                            const Text(
                          'Edit Shop Profile',
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
                ),
    );
  }

  // ===============================================================
  // SHOP IMAGE PLACEHOLDER
  // ===============================================================

  Widget _placeholder() {
    return Container(
      height: 200,
      decoration:
          BoxDecoration(
        color:
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.store,
          size: 64,
          color:
              Colors.grey.shade500,
        ),
      ),
    );
  }

  // ===============================================================
  // FORMAT SHOP TYPE
  // ===============================================================

  String _formatShopType(
    dynamic value,
  ) {
    switch (value?.toString()) {
      case 'parlour':
        return 'Parlour';

      case 'unisexsalon':
        return 'Unisex Salon';

      case 'salon':
        return 'Salon';

      default:
        return 'Not set';
    }
  }

  // ===============================================================
  // PROFILE INFORMATION ROW
  // ===============================================================

  Widget _row(
    IconData icon,
    String label,
    dynamic value,
    Color primaryColor,
  ) {
    final textValue =
        value == null ||
                value
                    .toString()
                    .trim()
                    .isEmpty
            ? 'Not set'
            : value.toString();

    return ListTile(
      leading:
          Icon(
        icon,
        color:
            primaryColor,
      ),
      title:
          Text(
        label,
        style:
            const TextStyle(
          fontWeight:
              FontWeight.w600,
          fontSize:
              13,
          color:
              Colors.grey,
        ),
      ),
      subtitle:
          Text(
        textValue,
        style:
            TextStyle(
          fontWeight:
              textValue ==
                      'Not set'
                  ? FontWeight
                      .normal
                  : FontWeight
                      .bold,
          fontSize:
              15,
          color:
              textValue ==
                      'Not set'
                  ? Colors
                      .grey
                      .shade400
                  : Colors
                      .black87,
        ),
      ),
    );
  }

  // ===============================================================
  // EDIT SHOP
  // ===============================================================

  Future<void> _edit() async {
    final changed =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditSalonScreen(
          initial:
              Map<String, dynamic>.from(
            c.shop!,
          ),
        ),
      ),
    );

    if (changed == true) {
      c.load();
    }
  }
}

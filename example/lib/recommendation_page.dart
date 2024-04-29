import 'package:flutter/material.dart';
import 'package:reteno_plugin/reteno.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({super.key});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  Future<List<RetenoRecommendation>>? future;
  final ValueNotifier<RecommendationSettings> _settingsNotifier =
      ValueNotifier(RecommendationSettings.defaultSettings());
  @override
  void initState() {
    super.initState();
    getRecommendations(_settingsNotifier.value);

    _settingsNotifier.addListener(() {
      getRecommendations(_settingsNotifier.value);
      setState(() {});
    });
  }

  Future<void> getRecommendations(RecommendationSettings settings) async {
    future = Reteno().getRecommendations(
      recomenedationVariantId: settings.recomenedationVariantId,
      productIds: settings.productIds,
      categoryId: settings.categoryId,
      filters: settings.filters,
      fields: settings.fields,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final newSettings =
                  await Navigator.of(context).push<RecommendationSettings>(
                MaterialPageRoute(
                  builder: (context) => RecommendationSettingsPage(
                    settings: _settingsNotifier.value,
                  ),
                ),
              );
              if (newSettings != null) {
                _settingsNotifier.value = newSettings;
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: future,
          builder: ((context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final recommendation = snapshot.data![index];
                  return ListTile(
                    title: Text(recommendation.name ?? ''),
                    subtitle: Text(recommendation.description ?? ''),
                    leading: Image.network(
                      recommendation.imageUrl ?? '',
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.red,
                        width: 50,
                        height: 50,
                      ),
                    ),
                    trailing: recommendation.price != null
                        ? Text('\$${recommendation.price}')
                        : null,
                    onTap: () async {
                      // Log recommendation event
                      try {
                        await Reteno().logRecommendationsEvent(
                          RetenoRecomEvents(
                            recomVariantId:
                                _settingsNotifier.value.recomenedationVariantId,
                            events: [
                              RetenoRecomEvent(
                                productId: recommendation.productId,
                                dateOccurred: DateTime.now(),
                                eventType: RetenoRecomEventType.click,
                              ),
                            ],
                          ),
                        );
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Recommendation Event Logged'),
                              content: Text(
                                'Recomenedation Variant Id: ${_settingsNotifier.value.recomenedationVariantId} Product ID: ${recommendation.productId} Clicked',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        print(e);
                      }
                    },
                  );
                },
              );
            }
            return Center(
              child: Text('Error fetching recommendations. ${snapshot.error}'),
            );
          }),
        ),
      ),
    );
  }
}

class RecommendationSettings {
  const RecommendationSettings({
    required this.recomenedationVariantId,
    required this.productIds,
    required this.categoryId,
    required this.filters,
    required this.fields,
  });
  final String recomenedationVariantId;
  final List<String> productIds;
  final String categoryId;
  final List<RetenoRecomendationFilter> filters;
  final List<String>? fields;

  factory RecommendationSettings.defaultSettings() {
    return RecommendationSettings(
      recomenedationVariantId: 'r1107v1482',
      productIds: ['240-LV09', '24-WG080'],
      categoryId: 'Default Category/Training/Video Download',
      filters: [
        RetenoRecomendationFilter(name: 'price', values: ['0-10']),
      ],
      fields: ['productId', 'name', 'descr', 'imageUrl', 'price'],
    );
  }

  RecommendationSettings copyWith({
    String? recomenedationVariantId,
    List<String>? productIds,
    String? categoryId,
    List<RetenoRecomendationFilter>? filters,
    List<String>? fields,
  }) {
    return RecommendationSettings(
      recomenedationVariantId:
          recomenedationVariantId ?? this.recomenedationVariantId,
      productIds: productIds ?? this.productIds,
      categoryId: categoryId ?? this.categoryId,
      filters: filters ?? this.filters,
      fields: fields ?? this.fields,
    );
  }
}

class RecommendationSettingsPage extends StatefulWidget {
  const RecommendationSettingsPage({super.key, required this.settings});
  final RecommendationSettings settings;

  @override
  State<RecommendationSettingsPage> createState() =>
      _RecommendationSettingsPageState();
}

class _RecommendationSettingsPageState
    extends State<RecommendationSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final ValueNotifier<RecommendationSettings> _settingsNotifier;

  @override
  void initState() {
    super.initState();
    _settingsNotifier = ValueNotifier(widget.settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendation Settings'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Recommendation Variant ID'),
                  initialValue: _settingsNotifier.value.recomenedationVariantId,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a value'
                      : null,
                  onSaved: (value) {
                    _settingsNotifier.value = _settingsNotifier.value
                        .copyWith(recomenedationVariantId: value);
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Category ID'),
                  initialValue: _settingsNotifier.value.categoryId,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a value'
                      : null,
                  onSaved: (value) {
                    _settingsNotifier.value =
                        _settingsNotifier.value.copyWith(categoryId: value);
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Product IDs: (comma separated)'),
                  initialValue: _settingsNotifier.value.productIds.join(','),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a value'
                      : null,
                  onSaved: (value) {
                    if (value != null) {
                      _settingsNotifier.value = _settingsNotifier.value
                          .copyWith(productIds: value.split(','));
                    }
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Fields: (comma separated)'),
                  initialValue: _settingsNotifier.value.fields?.join(','),
                  onSaved: (value) {
                    _settingsNotifier.value = _settingsNotifier.value
                        .copyWith(fields: value?.split(','));
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Filters:'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        final filter =
                            await showDialog<RetenoRecomendationFilter>(
                          context: context,
                          builder: (context) => const FilterDialog(),
                        );
                        if (filter != null) {
                          _settingsNotifier.value =
                              _settingsNotifier.value.copyWith(
                            filters: [
                              ..._settingsNotifier.value.filters,
                              filter
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
                ValueListenableBuilder(
                    valueListenable: _settingsNotifier,
                    builder: (context, value, child) {
                      return Wrap(
                        children: value.filters
                            .map(
                              (filter) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: InputChip(
                                  label: Text(
                                      '${filter.name}: ${filter.values.join(',')}'),
                                  onDeleted: () {
                                    _settingsNotifier.value =
                                        _settingsNotifier.value.copyWith(
                                      filters: _settingsNotifier.value.filters
                                          .where((f) => f != filter)
                                          .toList(),
                                    );
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      );
                    }),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      Navigator.of(context).pop(_settingsNotifier.value);
                    }
                  },
                  child: const Text('Get Recommendations'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _valuesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _valuesController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Filter'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter a value'
                  : null,
            ),
            TextFormField(
              controller: _valuesController,
              decoration:
                  const InputDecoration(labelText: 'Values (comma separated)'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter a value'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                RetenoRecomendationFilter(
                  name: _nameController.text,
                  values: _valuesController.text.split(','),
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

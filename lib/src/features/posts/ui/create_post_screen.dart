import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../../../core/models/catalog_models.dart';
import '../../../core/models/post_models.dart';
import '../../../services/api_client.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const _allowedMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };
  static const _maxImageBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _eventDateController = TextEditingController();
  final _stakeController = TextEditingController(text: '10');

  bool _loading = true;
  bool _submitting = false;
  bool _uploadingImage = false;
  String? _errorMessage;
  String? _imageError;
  PostType _type = PostType.analysis;
  PostVisibility _visibility = PostVisibility.public;
  ResultStatus _resultStatus = ResultStatus.pending;
  int? _sportId;
  int? _competitionId;
  int? _sportsbookId;
  final Set<int> _parleyCompetitionIds = {};
  List<CatalogItem> _sports = const [];
  List<CompetitionItem> _competitions = const [];
  List<SportsbookItem> _sportsbooks = const [];
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    _eventDateController.dispose();
    _stakeController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        widget.apiClient.getSports(),
        widget.apiClient.getCompetitions(),
        widget.apiClient.getSportsbooks(),
      ]);

      if (!mounted) {
        return;
      }

      final sports = (results[0] as List<CatalogItem>)
          .where((item) => item.active)
          .toList();
      final competitions = (results[1] as List<CompetitionItem>)
          .where((item) => item.active)
          .toList();
      final sportsbooks = (results[2] as List<SportsbookItem>)
          .where((item) => item.active)
          .toList();

      setState(() {
        _sports = sports;
        _competitions = competitions;
        _sportsbooks = sportsbooks;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'No se pudieron cargar los catalogos.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<CompetitionItem> get _visibleCompetitions {
    if (_sportId == null) {
      return _competitions;
    }
    return _competitions.where((item) => item.sportId == _sportId).toList();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 2))),
    );

    if (time == null) {
      return;
    }

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    _eventDateController.text = dateTime.toIso8601String();
    setState(() {});
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (picked == null || !mounted) {
        return;
      }

      final bytes = await picked.length();
      final mimeType = picked.mimeType ?? _guessMimeType(picked.name);

      if (!_allowedMimeTypes.contains(mimeType)) {
        setState(() {
          _imageError = 'Usa una imagen JPG, PNG o WebP.';
        });
        return;
      }

      if (bytes > _maxImageBytes) {
        setState(() {
          _imageError = 'La imagen no debe pesar mas de 5 MB.';
        });
        return;
      }

      setState(() {
        _selectedImage = picked;
        _imageError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _imageError = 'No se pudo seleccionar la imagen.';
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageError = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_type == PostType.pickSimple) {
      if (_sportId == null || _competitionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona deporte y liga.')),
        );
        return;
      }
    }

    if (_type == PostType.parley && _parleyCompetitionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una liga para el parley.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      String? uploadedImageKey;
      if (_selectedImage != null) {
        setState(() {
          _uploadingImage = true;
          _imageError = null;
        });

        final imageBytes = await _selectedImage!.readAsBytes();
        final mimeType =
            _selectedImage!.mimeType ?? _guessMimeType(_selectedImage!.name);
        final upload = await widget.apiClient.uploadPostImage(
          bytes: imageBytes,
          contentType: mimeType,
        );
        uploadedImageKey = upload.objectKey;

        if (mounted) {
          setState(() {
            _uploadingImage = false;
          });
        }
      }

      final tags = _tagsController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();

      final payload = CreatePostPayload(
        type: _type,
        content: _contentController.text.trim(),
        tags: tags,
        visibility: _visibility,
        imageKey: uploadedImageKey,
        simplePick: _type == PostType.pickSimple
            ? CreateSimplePickPayload(
                sportId: _sportId!,
                leagueId: _competitionId!,
                stake: int.parse(_stakeController.text.trim()),
                eventDate: _eventDateController.text.trim(),
                resultStatus: _resultStatus,
                sportsbookId: _sportsbookId,
              )
            : null,
        parley: _type == PostType.parley
            ? CreateParleyPayload(
                stake: int.parse(_stakeController.text.trim()),
                eventDate: _eventDateController.text.trim(),
                resultStatus: _resultStatus,
                sportsbookId: _sportsbookId,
                selections: _parleyCompetitionIds
                    .map((competitionId) {
                      final competition = _competitions.firstWhere(
                        (item) => item.id == competitionId,
                      );
                      return CreateParleySelectionPayload(
                        sportId: competition.sportId,
                        leagueId: competition.id,
                      );
                    })
                    .toList(),
              )
            : null,
      );

      final created = await widget.apiClient.createPost(payload);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(created);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear el post.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploadingImage = false;
        });
      }
    }
  }

  String _guessMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo post'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _loadCatalogs();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Comparte tu lectura del evento',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Migracion inicial del composer de Picka2 para Flutter. Ya soporta analisis, pick simple y parley.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 20),
                              DropdownButtonFormField<PostType>(
                                initialValue: _type,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de post',
                                ),
                                items: PostType.values
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(item.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() {
                                    _type = value;
                                    _competitionId = null;
                                    _parleyCompetitionIds.clear();
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contentController,
                                minLines: 4,
                                maxLines: 8,
                                decoration: const InputDecoration(
                                  labelText: 'Contenido',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Escribe el contenido del post.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _tagsController,
                                decoration: const InputDecoration(
                                  labelText: 'Tags separados por coma',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F8FB),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(0xFFE1EAF2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Imagen opcional',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: _submitting
                                              ? null
                                              : () {
                                                  _pickImage();
                                                },
                                          icon: const Icon(
                                            Icons.add_photo_alternate_outlined,
                                          ),
                                          label: Text(
                                            _selectedImage == null
                                                ? 'Elegir imagen'
                                                : 'Cambiar',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Formatos: JPG, PNG o WebP. Maximo 5 MB.',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    if (_selectedImage != null) ...[
                                      const SizedBox(height: 14),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: FutureBuilder<Uint8List>(
                                          future: _selectedImage!.readAsBytes(),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                              return const SizedBox(
                                                height: 180,
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            }

                                            return Image.memory(
                                              snapshot.data!,
                                              height: 180,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _selectedImage!.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _submitting
                                                ? null
                                                : _removeImage,
                                            child: const Text('Quitar'),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (_uploadingImage) ...[
                                      const SizedBox(height: 10),
                                      const LinearProgressIndicator(),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Subiendo imagen...',
                                      ),
                                    ],
                                    if (_imageError != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        _imageError!,
                                        style: const TextStyle(
                                          color: Color(0xFFC53838),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<PostVisibility>(
                                initialValue: _visibility,
                                decoration: const InputDecoration(
                                  labelText: 'Visibilidad',
                                ),
                                items: PostVisibility.values
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(item.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _visibility = value;
                                    });
                                  }
                                },
                              ),
                              if (_type != PostType.analysis) ...[
                                const SizedBox(height: 16),
                                DropdownButtonFormField<int>(
                                  initialValue: _sportId,
                                  decoration: const InputDecoration(
                                    labelText: 'Deporte',
                                  ),
                                  items: _sports
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item.id,
                                          child: Text(item.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _sportId = value;
                                      _competitionId = null;
                                      _parleyCompetitionIds.clear();
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _stakeController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Stake (10-100)',
                                  ),
                                  validator: (value) {
                                    if (_type == PostType.analysis) {
                                      return null;
                                    }
                                    final stake = int.tryParse(value ?? '');
                                    if (stake == null || stake < 10 || stake > 100) {
                                      return 'Usa un stake entre 10 y 100.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _eventDateController,
                                  readOnly: true,
                                  onTap: _pickDate,
                                  decoration: const InputDecoration(
                                    labelText: 'Fecha del evento',
                                  ),
                                  validator: (value) {
                                    if (_type == PostType.analysis) {
                                      return null;
                                    }
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Selecciona la fecha del evento.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<ResultStatus>(
                                  initialValue: _resultStatus,
                                  decoration: const InputDecoration(
                                    labelText: 'Estado',
                                  ),
                                  items: ResultStatus.values
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item,
                                          child: Text(item.label),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _resultStatus = value;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<int>(
                                  initialValue: _sportsbookId,
                                  decoration: const InputDecoration(
                                    labelText: 'Sportsbook',
                                  ),
                                  items: [
                                    const DropdownMenuItem<int>(
                                      value: null,
                                      child: Text('Sin sportsbook'),
                                    ),
                                    ..._sportsbooks.map(
                                      (item) => DropdownMenuItem(
                                        value: item.id,
                                        child: Text(item.name),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _sportsbookId = value;
                                    });
                                  },
                                ),
                              ],
                              if (_type == PostType.pickSimple) ...[
                                const SizedBox(height: 16),
                                DropdownButtonFormField<int>(
                                  initialValue: _competitionId,
                                  decoration: const InputDecoration(
                                    labelText: 'Liga',
                                  ),
                                  items: _visibleCompetitions
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item.id,
                                          child: Text(item.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _competitionId = value;
                                    });
                                  },
                                ),
                              ],
                              if (_type == PostType.parley) ...[
                                const SizedBox(height: 18),
                                Text(
                                  'Ligas del parley',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: _visibleCompetitions
                                      .map(
                                        (item) => FilterChip(
                                          selected: _parleyCompetitionIds.contains(item.id),
                                          label: Text(item.name),
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                _parleyCompetitionIds.add(item.id);
                                              } else {
                                                _parleyCompetitionIds.remove(item.id);
                                              }
                                            });
                                          },
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _submitting || _uploadingImage
                                    ? null
                                    : () {
                                        _submit();
                                      },
                                child: _submitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Publicar post'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}

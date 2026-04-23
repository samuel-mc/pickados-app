import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_theme.dart';
import '../../../core/models/catalog_models.dart';
import '../../../core/models/post_models.dart';
import '../../../services/api_client.dart';

class CreatePostV2Screen extends StatefulWidget {
  const CreatePostV2Screen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<CreatePostV2Screen> createState() => _CreatePostV2ScreenState();
}

class _CreatePostV2ScreenState extends State<CreatePostV2Screen> {
  static const _allowedMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };
  static const _maxImageBytes = 5 * 1024 * 1024;

  static const _stakeOptions = [
    10,
    20,
    30,
    40,
    50,
    60,
    70,
    80,
    90,
    100,
  ];

  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _eventDateController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _loading = true;
  bool _submitting = false;
  bool _uploadingImage = false;
  String? _errorMessage;
  String? _imageError;
  String _homePrashe = '';

  PostType _type = PostType.analysis;
  PostVisibility _visibility = PostVisibility.public;
  ResultStatus _resultStatus = ResultStatus.pending;

  int? _sportId;
  int? _competitionId;
  int? _sportsbookId;
  int? _stake;

  int? _parleySportFilterId;
  final Set<int> _parleyCompetitionIds = {};

  List<CatalogItem> _sports = const [];
  List<CompetitionItem> _competitions = const [];
  List<SportsbookItem> _sportsbooks = const [];
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    _eventDateController.dispose();
    super.dispose();
  }

  Future<void> _loadForm() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        widget.apiClient.getSports(),
        widget.apiClient.getCompetitions(),
        widget.apiClient.getSportsbooks(),
        widget.apiClient.getHomePrashe(),
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
      final prashe = results[3] as CatalogItem?;

      setState(() {
        _sports = sports;
        _competitions = competitions;
        _sportsbooks = sportsbooks;
        _homePrashe = prashe?.name ?? '';
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
        _errorMessage = 'No se pudo cargar el formulario.';
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

  List<CompetitionItem> get _visibleParleyCompetitions {
    if (_parleySportFilterId == null) {
      return _competitions;
    }
    return _competitions
        .where((item) => item.sportId == _parleySportFilterId)
        .toList();
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

  void _setType(PostType type) {
    setState(() {
      _type = type;
      _sportId = null;
      _competitionId = null;
      _parleyCompetitionIds.clear();
      _parleySportFilterId = null;
      _sportsbookId = null;
      _stake = null;
      _eventDateController.text = '';
      _resultStatus = ResultStatus.pending;
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
      if (_stake == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona el stake.')),
        );
        return;
      }
      if (_eventDateController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona la fecha del evento.')),
        );
        return;
      }
    }

    if (_type == PostType.parley) {
      if (_parleyCompetitionIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona al menos una liga.')),
        );
        return;
      }
      if (_stake == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona el stake.')),
        );
        return;
      }
      if (_eventDateController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona la fecha del evento.')),
        );
        return;
      }
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
                stake: _stake!,
                eventDate: _eventDateController.text.trim(),
                resultStatus: _resultStatus,
                sportsbookId: _sportsbookId,
              )
            : null,
        parley: _type == PostType.parley
            ? CreateParleyPayload(
                stake: _stake!,
                eventDate: _eventDateController.text.trim(),
                resultStatus: _resultStatus,
                sportsbookId: _sportsbookId,
                selections: _parleyCompetitionIds.map((competitionId) {
                  final competition = _competitions.firstWhere(
                    (item) => item.id == competitionId,
                  );
                  return CreateParleySelectionPayload(
                    sportId: competition.sportId,
                    leagueId: competition.id,
                  );
                }).toList(),
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
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;

    return Scaffold(
      backgroundColor: colors.pageGradientBottom,
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
                          onPressed: _loadForm,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroCard(
                          title: _homePrashe.isNotEmpty
                              ? _homePrashe
                              : 'Crea un post que se vea claro y contundente.',
                          subtitle:
                              'Diseña tu publicación con contexto, ticket y visibilidad desde una vista pensada para mobile.',
                        ),
                        const SizedBox(height: 14),
                        Form(
                          key: _formKey,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tipo de post',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _TypeChip(
                                        selected: _type == PostType.analysis,
                                        label: PostType.analysis.label,
                                        onTap: () => _setType(PostType.analysis),
                                      ),
                                      _TypeChip(
                                        selected: _type == PostType.pickSimple,
                                        label: PostType.pickSimple.label,
                                        onTap: () => _setType(PostType.pickSimple),
                                      ),
                                      _TypeChip(
                                        selected: _type == PostType.parley,
                                        label: PostType.parley.label,
                                        onTap: () => _setType(PostType.parley),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  _SectionHeader(
                                    title: 'Contexto del post',
                                    subtitle:
                                        'Explica el razonamiento detrás del análisis o del ticket.',
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _contentController,
                                    minLines: 5,
                                    maxLines: 10,
                                    decoration: const InputDecoration(
                                      labelText: 'Contenido',
                                      hintText:
                                          'Comparte tu análisis, pick o contexto del parley...',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Escribe el contenido del post.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  _SectionHeader(
                                    title: 'Presentación',
                                    subtitle:
                                        'Ajusta visibilidad, apoyo visual y etiquetas para ordenar el contenido.',
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _tagsController,
                                    decoration: const InputDecoration(
                                      labelText: 'Tags',
                                      hintText: 'NBA, underdogs, value',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
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
                                      if (value == null) return;
                                      setState(() {
                                        _visibility = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _ImagePickerCard(
                                    selectedImage: _selectedImage,
                                    uploading: _uploadingImage,
                                    error: _imageError,
                                    onPick: _submitting ? null : _pickImage,
                                    onRemove: _submitting ? null : _removeImage,
                                  ),
                                  if (_type == PostType.pickSimple) ...[
                                    const SizedBox(height: 18),
                                    _SectionHeader(
                                      title: 'Datos del pick',
                                      subtitle:
                                          'Selecciona el contexto del pick y el stake de forma estructurada.',
                                    ),
                                    const SizedBox(height: 10),
                                    DropdownButtonFormField<int>(
                                      initialValue: _sportId,
                                      decoration: const InputDecoration(
                                        labelText: 'Deporte',
                                      ),
                                      items: [
                                        const DropdownMenuItem<int>(
                                          value: null,
                                          child: Text('Selecciona deporte'),
                                        ),
                                        ..._sports.map(
                                          (item) => DropdownMenuItem(
                                            value: item.id,
                                            child: Text(item.name),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _sportId = value;
                                          _competitionId = null;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<int>(
                                      initialValue: _competitionId,
                                      decoration: const InputDecoration(
                                        labelText: 'Liga',
                                      ),
                                      items: [
                                        const DropdownMenuItem<int>(
                                          value: null,
                                          child: Text('Selecciona liga'),
                                        ),
                                        ..._visibleCompetitions.map(
                                          (item) => DropdownMenuItem(
                                            value: item.id,
                                            child: Text(item.name),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _competitionId = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<int>(
                                      initialValue: _stake,
                                      decoration: const InputDecoration(
                                        labelText: 'Stake',
                                      ),
                                      items: [
                                        const DropdownMenuItem<int>(
                                          value: null,
                                          child: Text('Selecciona stake'),
                                        ),
                                        ..._stakeOptions.map(
                                          (value) => DropdownMenuItem(
                                            value: value,
                                            child: Text('$value'),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _stake = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<int>(
                                      initialValue: _sportsbookId,
                                      decoration: const InputDecoration(
                                        labelText: 'Casa de apuesta',
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
                                    const SizedBox(height: 12),
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
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<ResultStatus>(
                                      initialValue: _resultStatus,
                                      decoration: const InputDecoration(
                                        labelText: 'Estado inicial',
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
                                        if (value == null) return;
                                        setState(() {
                                          _resultStatus = value;
                                        });
                                      },
                                    ),
                                  ],
                                  if (_type == PostType.parley) ...[
                                    const SizedBox(height: 18),
                                    _SectionHeader(
                                      title: 'Datos generales de la boleta',
                                      subtitle:
                                          'Marca una o varias ligas para armar el parley.',
                                    ),
                                    const SizedBox(height: 10),
                                    DropdownButtonFormField<int>(
                                      initialValue: _stake,
                                      decoration: const InputDecoration(
                                        labelText: 'Stake',
                                      ),
                                      items: [
                                        const DropdownMenuItem<int>(
                                          value: null,
                                          child: Text('Selecciona stake'),
                                        ),
                                        ..._stakeOptions.map(
                                          (value) => DropdownMenuItem(
                                            value: value,
                                            child: Text('$value'),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _stake = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<int>(
                                      initialValue: _sportsbookId,
                                      decoration: const InputDecoration(
                                        labelText: 'Casa de apuesta',
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
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _eventDateController,
                                      readOnly: true,
                                      onTap: _pickDate,
                                      decoration: const InputDecoration(
                                        labelText: 'Fecha de la boleta',
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
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<ResultStatus>(
                                      initialValue: _resultStatus,
                                      decoration: const InputDecoration(
                                        labelText: 'Estado inicial',
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
                                        if (value == null) return;
                                        setState(() {
                                          _resultStatus = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<int>(
                                      initialValue: _parleySportFilterId,
                                      decoration: const InputDecoration(
                                        labelText: 'Filtrar por deporte (opcional)',
                                      ),
                                      items: [
                                        const DropdownMenuItem<int>(
                                          value: null,
                                          child: Text('Todos los deportes'),
                                        ),
                                        ..._sports.map(
                                          (item) => DropdownMenuItem(
                                            value: item.id,
                                            child: Text(item.name),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _parleySportFilterId = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Ligas del parley',
                                            style: theme.textTheme.titleMedium,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.blueSurface,
                                            borderRadius: BorderRadius.circular(999),
                                            border: Border.all(color: colors.borderSoft),
                                          ),
                                          child: Text(
                                            '${_parleyCompetitionIds.length} seleccionadas',
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: _visibleParleyCompetitions
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
                                  const SizedBox(height: 18),
                                  FilledButton.icon(
                                    onPressed: _submitting || _uploadingImage
                                        ? null
                                        : _submit,
                                    icon: _submitting
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.send_rounded),
                                    label: Text(
                                      _submitting ? 'Publicando...' : 'Publicar post',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF0D2F4F),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipster Network',
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF9DC4E6),
              fontWeight: FontWeight.w800,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFD5E5F4),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;
    return Material(
      color: selected ? theme.colorScheme.primary : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : colors.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.selectedImage,
    required this.uploading,
    required this.error,
    required this.onPick,
    required this.onRemove,
  });

  final XFile? selectedImage;
  final bool uploading;
  final String? error;
  final Future<void> Function()? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.blueSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Imagen opcional',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onPick == null ? null : () => onPick!.call(),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(selectedImage == null ? 'Elegir' : 'Cambiar'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Formatos: JPG, PNG o WebP. Máximo 5 MB.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          if (selectedImage != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FutureBuilder<Uint8List>(
                future: selectedImage!.readAsBytes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
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
                    selectedImage!.name,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: onRemove,
                  child: const Text('Quitar'),
                ),
              ],
            ),
          ],
          if (uploading) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Subiendo imagen...'),
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(
                color: Color(0xFFC53838),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


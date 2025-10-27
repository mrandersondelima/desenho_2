import 'dart:convert';

class Project {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime lastModified;

  // Configurações das imagens sobrepostas
  final List<String> overlayImagePaths; // Lista de caminhos das imagens
  final int currentImageIndex; // Índice da imagem atualmente exibida
  final double imageOpacity;
  final double imagePositionX;
  final double imagePositionY;
  final double imageScale;
  final double imageRotation;
  final bool showOverlayImage;

  // Posições da câmera (para sincronização no modo desenho)
  final double cameraPositionX;
  final double cameraPositionY;
  final double cameraScale;

  const Project({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastModified,
    this.overlayImagePaths = const [],
    this.currentImageIndex = 0,
    this.imageOpacity = 0.5,
    this.imagePositionX = 0.0,
    this.imagePositionY = 0.0,
    this.imageScale = 1.0,
    this.imageRotation = 0.0,
    this.showOverlayImage = true,
    this.cameraPositionX = 0.0,
    this.cameraPositionY = 0.0,
    this.cameraScale = 1.0,
  });

  // Construtor para criar um novo projeto
  factory Project.create(String name) {
    final now = DateTime.now();
    return Project(
      id: generateId(),
      name: name,
      createdAt: now,
      lastModified: now,
    );
  }

  // Gera um ID único baseado no timestamp
  static String generateId() {
    return 'project_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Copia o projeto com novos valores
  Project copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastModified,
    List<String>? overlayImagePaths,
    int? currentImageIndex,
    double? imageOpacity,
    double? imagePositionX,
    double? imagePositionY,
    double? imageScale,
    double? imageRotation,
    bool? showOverlayImage,
    double? cameraPositionX,
    double? cameraPositionY,
    double? cameraScale,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? DateTime.now(),
      overlayImagePaths: overlayImagePaths ?? this.overlayImagePaths,
      currentImageIndex: currentImageIndex ?? this.currentImageIndex,
      imageOpacity: imageOpacity ?? this.imageOpacity,
      imagePositionX: imagePositionX ?? this.imagePositionX,
      imagePositionY: imagePositionY ?? this.imagePositionY,
      imageScale: imageScale ?? this.imageScale,
      imageRotation: imageRotation ?? this.imageRotation,
      showOverlayImage: showOverlayImage ?? this.showOverlayImage,
      cameraPositionX: cameraPositionX ?? this.cameraPositionX,
      cameraPositionY: cameraPositionY ?? this.cameraPositionY,
      cameraScale: cameraScale ?? this.cameraScale,
    );
  }

  // Converte para Map para serialização
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastModified': lastModified.millisecondsSinceEpoch,
      'overlayImagePaths': overlayImagePaths,
      'currentImageIndex': currentImageIndex,
      'imageOpacity': imageOpacity,
      'imagePositionX': imagePositionX,
      'imagePositionY': imagePositionY,
      'imageScale': imageScale,
      'imageRotation': imageRotation,
      'showOverlayImage': showOverlayImage,
      'cameraPositionX': cameraPositionX,
      'cameraPositionY': cameraPositionY,
      'cameraScale': cameraScale,
    };
  }

  // Cria Project a partir de Map
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastModified: DateTime.fromMillisecondsSinceEpoch(
        map['lastModified'] ?? 0,
      ),
      overlayImagePaths: List<String>.from(map['overlayImagePaths'] ?? []),
      currentImageIndex: map['currentImageIndex']?.toInt() ?? 0,
      imageOpacity: (map['imageOpacity'] ?? 0.5).toDouble(),
      imagePositionX: (map['imagePositionX'] ?? 0.0).toDouble(),
      imagePositionY: (map['imagePositionY'] ?? 0.0).toDouble(),
      imageScale: (map['imageScale'] ?? 1.0).toDouble(),
      imageRotation: (map['imageRotation'] ?? 0.0).toDouble(),
      showOverlayImage: map['showOverlayImage'] ?? true,
      cameraPositionX: (map['cameraPositionX'] ?? 0.0).toDouble(),
      cameraPositionY: (map['cameraPositionY'] ?? 0.0).toDouble(),
      cameraScale: (map['cameraScale'] ?? 1.0).toDouble(),
    );
  }

  // Converte para JSON string
  String toJson() => json.encode(toMap());

  // Cria Project a partir de JSON string
  factory Project.fromJson(String source) =>
      Project.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Project(id: $id, name: $name, createdAt: $createdAt, lastModified: $lastModified, overlayImagePaths: $overlayImagePaths, currentImageIndex: $currentImageIndex, imageOpacity: $imageOpacity, imagePositionX: $imagePositionX, imagePositionY: $imagePositionY, imageScale: $imageScale, imageRotation: $imageRotation, showOverlayImage: $showOverlayImage, cameraPositionX: $cameraPositionX, cameraPositionY: $cameraPositionY, cameraScale: $cameraScale)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Project &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.lastModified == lastModified &&
        _listEquals(other.overlayImagePaths, overlayImagePaths) &&
        other.currentImageIndex == currentImageIndex &&
        other.imageOpacity == imageOpacity &&
        other.imagePositionX == imagePositionX &&
        other.imagePositionY == imagePositionY &&
        other.imageScale == imageScale &&
        other.imageRotation == imageRotation &&
        other.showOverlayImage == showOverlayImage &&
        other.cameraPositionX == cameraPositionX &&
        other.cameraPositionY == cameraPositionY &&
        other.cameraScale == cameraScale;
  }

  // Helper function para comparar listas
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        createdAt.hashCode ^
        lastModified.hashCode ^
        overlayImagePaths.hashCode ^
        currentImageIndex.hashCode ^
        imageOpacity.hashCode ^
        imagePositionX.hashCode ^
        imagePositionY.hashCode ^
        imageScale.hashCode ^
        imageRotation.hashCode ^
        showOverlayImage.hashCode ^
        cameraPositionX.hashCode ^
        cameraPositionY.hashCode ^
        cameraScale.hashCode;
  }

  // Getters de conveniência
  bool get hasOverlayImage => overlayImagePaths.isNotEmpty;

  String? get currentImagePath =>
      hasOverlayImage && currentImageIndex < overlayImagePaths.length
      ? overlayImagePaths[currentImageIndex]
      : null;

  String get formattedCreatedAt {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  String get formattedLastModified {
    return '${lastModified.day.toString().padLeft(2, '0')}/${lastModified.month.toString().padLeft(2, '0')}/${lastModified.year}';
  }
}

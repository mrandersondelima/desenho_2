import 'dart:io';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/project.dart';
import '../services/project_service.dart';

class CameraOverlayController extends GetxController {
  // Observable variables
  RxList<CameraDescription> cameras = <CameraDescription>[].obs;
  Rx<CameraController?> cameraController = Rx<CameraController?>(null);
  RxBool isCameraInitialized = false.obs;
  RxBool isLoading = true.obs;
  RxBool areControlsVisible = true.obs;

  // Estados dos botões da barra inferior
  RxBool isMoveButtonActive = false.obs;
  RxBool isHideButtonActive = false.obs;
  RxBool isOpacityButtonActive = false.obs;
  RxBool isToolsButtonActive = false.obs;
  RxBool isImageMoveButtonActive = false.obs;
  RxBool isCameraMoveButtonActive = false.obs;

  // Lista de imagens sobrepostas
  RxList<String> overlayImagePaths = <String>[].obs;
  RxInt currentImageIndex = 0.obs;

  // Getter para compatibilidade com código existente
  String get selectedImagePath =>
      overlayImagePaths.isNotEmpty &&
          currentImageIndex.value < overlayImagePaths.length
      ? overlayImagePaths[currentImageIndex.value]
      : '';

  bool get hasOverlayImages => overlayImagePaths.isNotEmpty;
  RxBool isMoveBarExpanded = false.obs;
  RxBool isOpacityBarExpanded = false.obs;
  RxBool isOpacitySwitchEnabled = true.obs; // Switch para controlar opacidade
  RxBool isToolsBarExpanded = false.obs; // Barra de ferramentas expandida
  RxBool isFlashBarExpanded = false.obs; // Barra do botão Piscar expandida
  RxBool isAngleBarExpanded = false.obs; // Barra do botão Ângulo expandida
  RxBool isVisibilityBarExpanded =
      false.obs; // Barra do botão Visualização expandida

  // Estados dos botões da barra de ferramentas
  RxBool isFlashButtonActive = false.obs;
  RxBool isIlluminationButtonActive = false.obs;
  RxBool isAngleButtonActive = false.obs;
  RxBool isVisibilityButtonActive = false.obs;

  RxDouble imageOpacity = 0.5.obs;
  RxBool showOverlayImage = true.obs;

  // ==================== VARIÁVEIS DA IMAGEM (SEMPRE VISÍVEIS) ====================
  // Estas são as variáveis da imagem que aparecem na tela
  // A imagem sempre usa os valores do modo ajuste
  RxDouble imagePositionX = 0.0.obs;
  RxDouble imagePositionY = 0.0.obs;
  RxDouble imageScale = 1.0.obs;
  RxDouble imageRotation = 0.0.obs;

  // ==================== VARIÁVEIS DO MODO AJUSTE ====================
  // Valores atuais da imagem (sempre usados para renderizar)
  double _adjustModePositionX = 0.0;
  double _adjustModePositionY = 0.0;
  double _adjustModeScale = 1.0;

  // ==================== VARIÁVEIS DO MODO DESENHO ====================
  // Valores usados APENAS para cálculos da câmera
  double _drawingModePositionX = 0.0;
  double _drawingModePositionY = 0.0;
  double _drawingModeScale = 1.0;

  // Posição da câmera (para sincronização no modo desenho)
  RxDouble cameraPositionX = 0.0.obs;
  RxDouble cameraPositionY = 0.0.obs;

  // Modo de interação é determinado pelo estado do botão de mover imagem
  // true = modo desenho (quando isImageMoveButtonActive = false)
  // false = modo ajuste (quando isImageMoveButtonActive = true)
  bool get isDrawingMode =>
      !isImageMoveButtonActive.value && !isCameraMoveButtonActive.value;

  // Toggle para transparência automática (apenas no modo desenho)
  RxBool isAutoTransparencyEnabled = false.obs;
  RxDouble autoTransparencyValue = 0.5.obs; // Valor atual da animação
  double _maxTransparencyValue = 0.5; // Valor máximo definido pelo slider

  // Zoom da câmera
  RxDouble cameraZoom = 1.0.obs;
  double _minCameraZoom = 1.0;
  double _maxCameraZoom = 8.0;

  // Escala adicional da câmera para quando zoom da imagem < 1.0
  RxDouble cameraScale = 1.0.obs;

  // Projeto atual
  Rx<Project?> currentProject = Rx<Project?>(null);
  final ProjectService _projectService = ProjectService();

  // TextEditingController para input de rotação
  final TextEditingController rotationTextController = TextEditingController();

  // Controllers para ajuste fino de dimensões
  final TextEditingController imageWidthController = TextEditingController();
  final TextEditingController imageHeightController = TextEditingController();

  // Dimensões originais da imagem
  RxDouble originalImageWidth = 0.0.obs;
  RxDouble originalImageHeight = 0.0.obs;
  RxDouble currentImageWidth = 0.0.obs;
  RxDouble currentImageHeight = 0.0.obs;

  // Internal gesture tracking
  late Offset _startFocalPoint;
  double _initialAdjustX = 0.0;
  double _initialAdjustY = 0.0;
  double _initialAdjustScale = 1.0;
  double _initialDrawingX = 0.0;
  double _initialDrawingY = 0.0;
  double _initialDrawingScale = 1.0;
  double _initialCameraX = 0.0;
  double _initialCameraY = 0.0;
  double _initialImageScale = 1.0;
  double _initialCameraScale = 1.0;
  double _initialImageX = 0.0;
  double _initialImageY = 0.0;
  double _initialImageRotation = 0.0;

  @override
  void onInit() {
    super.onInit();
    rotationTextController.text = '0';
    // Inicializa autoTransparencyValue com o valor padrão da imageOpacity
    autoTransparencyValue.value = imageOpacity.value;
    _maxTransparencyValue = imageOpacity.value;
    // Inicializa cameraScale
    cameraScale.value = 1.0;
    initializeCamera();
  }

  @override
  void onClose() {
    // Força salvamento antes de fechar
    forceSave();

    cameraController.value?.dispose();
    rotationTextController.dispose();
    imageWidthController.dispose();
    imageHeightController.dispose();
    super.onClose();
  }

  void toggleVisibility() {
    areControlsVisible.value = !areControlsVisible.value;
  }

  void toggleMoveButton() {
    // Desativa os outros botões
    isHideButtonActive.value = false;
    isOpacityButtonActive.value = false;
    isToolsButtonActive.value = false;
    // Alterna o estado do botão Mover (apenas para mostrar/esconder a barra secundária)
    isMoveButtonActive.value = !isMoveButtonActive.value;

    // Se estiver desativando o botão principal, desativa também os botões secundários
    if (!isMoveButtonActive.value) {
      isImageMoveButtonActive.value = false;
      isCameraMoveButtonActive.value = false;
    }

    // Fecha as outras barras quando a barra de movimento for ativada
    if (isMoveButtonActive.value) {
      isOpacityBarExpanded.value = false;
      isVisibilityBarExpanded.value = false;
    }
  }

  void toggleMoveImageButton() {
    // Desativa os outros botões
    isHideButtonActive.value = false;
    isOpacityButtonActive.value = false;
    isCameraMoveButtonActive.value = false;

    // Alterna o estado do botão Mover Imagem
    isImageMoveButtonActive.value = !isImageMoveButtonActive.value;

    // Quando isImageMoveButtonActive muda, o modo também muda automaticamente
    if (isImageMoveButtonActive.value) {
      // ==== ENTRANDO NO MODO AJUSTE ====
      // A imagem continua visível com valores _adjustMode*
      // A câmera fica parada (usa valores _drawingMode* que não mudam)

      // Se estava em modo desenho, desabilita a transparência automática
      if (isAutoTransparencyEnabled.value) {
        isAutoTransparencyEnabled.value = false;
        _stopAutoTransparencyAnimation();
      }
    } else {
      // ==== ENTRANDO NO MODO DESENHO ====
      // NÃO sincroniza valores - cada modo mantém seus próprios valores
      // Os valores _drawingMode* só serão atualizados durante gestos no modo desenho
    }

    _autoSave();
  }

  // Método auxiliar para sincronizar zoom da câmera com uma escala específica
  void _syncCameraZoomWithImageScale(double scale) {
    cameraScale.value = scale;

    if (scale >= 1.0) {
      final double imageZoomRange = 5.0 - 1.0;
      final double cameraZoomRange = _maxCameraZoom - _minCameraZoom;
      final double normalizedImageZoom = (scale - 1.0) / imageZoomRange;
      final double baseCameraZoom =
          _minCameraZoom + (normalizedImageZoom * cameraZoomRange);
      final double compensatedCameraZoom = baseCameraZoom / scale;
      setCameraZoomSync(
        compensatedCameraZoom.clamp(_minCameraZoom, _maxCameraZoom),
      );
    } else {
      setCameraZoomSync(_minCameraZoom);
    }
  }

  void toggleMoveCameraButton() {
    // Desativa os outros botões
    isHideButtonActive.value = false;
    isOpacityButtonActive.value = false;
    isImageMoveButtonActive.value = false;
    // Alterna o estado do botão Mover Câmera
    isCameraMoveButtonActive.value = !isCameraMoveButtonActive.value;
  }

  void toggleHideButton() {
    // Desativa os outros botões
    isMoveButtonActive.value = false;
    isOpacityButtonActive.value = false;
    isToolsButtonActive.value = false;
    // Alterna o estado do botão Esconder
    isHideButtonActive.value = !isHideButtonActive.value;
  }

  void toggleOpacityButton() {
    // Desativa os outros botões
    isMoveButtonActive.value = false;
    isHideButtonActive.value = false;
    isToolsButtonActive.value = false;
    // Alterna o estado do botão Opacidade
    isOpacityButtonActive.value = !isOpacityButtonActive.value;

    // Fecha a barra de movimento quando a barra de opacidade for ativada
    if (isOpacityButtonActive.value) {
      isMoveBarExpanded.value = false;
      isToolsBarExpanded.value = false;
      isFlashBarExpanded.value = false;
      isAngleBarExpanded.value = false;
      isVisibilityBarExpanded.value = false;
      // Desativa também os botões secundários da barra de movimento
      isImageMoveButtonActive.value = false;
      isCameraMoveButtonActive.value = false;
    }
  }

  void toggleToolsButton() {
    // Alterna o estado do botão Ferramentas
    isToolsButtonActive.value = !isToolsButtonActive.value;

    // Fecha as outras barras quando a barra de ferramentas for ativada
    if (isToolsButtonActive.value) {
      isFlashBarExpanded.value = false;
      isAngleBarExpanded.value = false;
      isVisibilityBarExpanded.value = false;
    }

    // Se estiver desativando o botão principal, fecha também a barra secundária
    // if (!isToolsButtonActive.value) {
    //   isToolsBarExpanded.value = false;
    //   isFlashButtonActive.value = false;
    //   isIlluminationButtonActive.value = false;
    // }
  }

  void toggleFlashButton() {
    // Desativa os outros botões da barra de ferramentas
    isIlluminationButtonActive.value = false;
    isAngleButtonActive.value = false;
    isVisibilityButtonActive.value = false;
    // Alterna o estado do botão Piscar
    isFlashButtonActive.value = !isFlashButtonActive.value;

    // Controla a expansão da barra do botão Piscar
    isFlashBarExpanded.value = isFlashButtonActive.value;

    // Se estiver ativando, fecha outras barras
    if (isFlashButtonActive.value) {
      isAngleBarExpanded.value = false;
      isVisibilityBarExpanded.value = false;
    }
  }

  void toggleIlluminationButton() {
    // Desativa os outros botões da barra de ferramentas
    isFlashButtonActive.value = false;
    isAngleButtonActive.value = false;
    isVisibilityButtonActive.value = false;
    // Alterna o estado do botão Iluminação
    isIlluminationButtonActive.value = !isIlluminationButtonActive.value;
  }

  void toggleAngleButton() {
    // Desativa os outros botões da barra de ferramentas
    isFlashButtonActive.value = false;
    isIlluminationButtonActive.value = false;
    isVisibilityButtonActive.value = false;
    // Alterna o estado do botão Ângulo
    isAngleButtonActive.value = !isAngleButtonActive.value;

    // Controla a expansão da barra do botão Ângulo
    isAngleBarExpanded.value = isAngleButtonActive.value;

    // Se estiver ativando, fecha outras barras
    if (isAngleButtonActive.value) {
      isFlashBarExpanded.value = false;
      isVisibilityBarExpanded.value = false;
    }
  }

  void toggleVisibilityButton() {
    // Desativa os outros botões da barra de ferramentas
    isFlashButtonActive.value = false;
    isIlluminationButtonActive.value = false;
    isAngleButtonActive.value = false;
    // Alterna o estado do botão Visualização
    isVisibilityButtonActive.value = !isVisibilityButtonActive.value;

    // Controla a expansão da barra do botão Visualização
    isVisibilityBarExpanded.value = isVisibilityButtonActive.value;

    // Se estiver ativando, fecha outras barras
    if (isVisibilityButtonActive.value) {
      isMoveBarExpanded.value = false;
      isOpacityBarExpanded.value = false;
      isFlashBarExpanded.value = false;
      isAngleBarExpanded.value = false;
    }
  }

  Future<void> initializeCamera() async {
    try {
      isLoading.value = true;

      // Solicita permissão da câmera
      final cameraPermission = await Permission.camera.request();
      if (cameraPermission != PermissionStatus.granted) {
        Get.snackbar('Erro', 'Permissão da câmera é necessária');
        return;
      }

      // Lista câmeras disponíveis
      cameras.value = await availableCameras();
      if (cameras.isEmpty) {
        Get.snackbar('Erro', 'Nenhuma câmera encontrada');
        return;
      }

      // Inicializa a câmera traseira (índice 0 geralmente é a traseira)
      await _setupCamera(cameras.first);
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao inicializar câmera: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    if (cameraController.value != null) {
      await cameraController.value!.dispose();
    }

    cameraController.value = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await cameraController.value!.initialize();

      // Desabilita o autofocus definindo um foco fixo
      // try {
      //   await cameraController.value!.setFocusMode(FocusMode.locked);
      // } catch (e) {
      //   print('Erro ao configurar foco: $e');
      //   // Se locked não funcionar, tenta auto uma vez e depois trava
      //   try {
      //     await cameraController.value!.setFocusMode(FocusMode.auto);
      //     // Aguarda um momento para o foco se ajustar
      //     await Future.delayed(const Duration(seconds: 2));
      //     await cameraController.value!.setFocusMode(FocusMode.locked);
      //   } catch (e2) {
      //     print('Erro ao configurar foco alternativo: $e2');
      //   }
      // }

      // Inicializa os valores de zoom da câmera
      _minCameraZoom = await cameraController.value!.getMinZoomLevel();
      _maxCameraZoom = await cameraController.value!.getMaxZoomLevel();
      cameraZoom.value = _minCameraZoom;

      isCameraInitialized.value = true;
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao configurar câmera: $e');
    }
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) return;

    final currentCamera = cameraController.value?.description;
    CameraDescription newCamera;

    if (currentCamera == cameras.first) {
      newCamera = cameras.last;
    } else {
      newCamera = cameras.first;
    }

    await _setupCamera(newCamera);
  }

  Future<void> pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        final newImagePath = result.files.single.path ?? '';
        if (newImagePath.isNotEmpty) {
          // Valida compatibilidade de dimensões
          final isCompatible = await _validateImageCompatibility(newImagePath);

          if (isCompatible) {
            // Adiciona nova imagem à lista
            overlayImagePaths.add(newImagePath);
            currentImageIndex.value =
                overlayImagePaths.length - 1; // Seleciona a nova imagem

            // Reset position and scale when new image is selected
            imagePositionX.value = 0.0;
            imagePositionY.value = 0.0;
            imageScale.value = 1.0;
            imageRotation.value = 0.0;
            rotationTextController.text = '0';

            // Inicializa transparência com valor atual da opacidade
            autoTransparencyValue.value = imageOpacity.value;
            _maxTransparencyValue = imageOpacity.value;

            // Carrega dimensões da imagem
            await _loadImageDimensions();

            _autoSave();

            Get.snackbar(
              'Imagem adicionada',
              'Imagem adicionada com sucesso',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
          } else {
            Get.snackbar(
              'Imagem incompatível',
              'Esta imagem tem dimensões diferentes das já selecionadas',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        }
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
    }
  }

  // Métodos para gerenciar múltiplas imagens
  void selectImageByIndex(int index) {
    if (index >= 0 && index < overlayImagePaths.length) {
      currentImageIndex.value = index;
      _loadImageDimensions();
      _autoSave();
    }
  }

  void removeImageAtIndex(int index) {
    if (index >= 0 && index < overlayImagePaths.length) {
      overlayImagePaths.removeAt(index);

      // Ajusta o índice atual se necessário
      if (currentImageIndex.value >= overlayImagePaths.length) {
        currentImageIndex.value = overlayImagePaths.length - 1;
      }
      if (currentImageIndex.value < 0) {
        currentImageIndex.value = 0;
      }

      _autoSave();
    }
  }

  void clearAllImages() {
    overlayImagePaths.clear();
    currentImageIndex.value = 0;
    _autoSave();
  }

  // Permite selecionar múltiplas imagens de uma vez
  Future<void> pickMultipleImagesFromGallery() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true, // Permite múltiplas seleções
      );

      if (result != null && result.files.isNotEmpty) {
        List<String> validImages = [];
        List<String> invalidImages = [];

        // Valida cada imagem selecionada
        for (var file in result.files) {
          if (file.path != null && file.path!.isNotEmpty) {
            // Valida compatibilidade de dimensões
            final isCompatible = await _validateImageCompatibility(file.path!);

            if (isCompatible) {
              validImages.add(file.path!);
            } else {
              invalidImages.add(file.name);
            }
          }
        }

        // Adiciona apenas as imagens válidas
        if (validImages.isNotEmpty) {
          overlayImagePaths.addAll(validImages);

          // Seleciona a primeira nova imagem
          if (overlayImagePaths.isNotEmpty) {
            currentImageIndex.value =
                overlayImagePaths.length - validImages.length;

            // Reset das transformações para a primeira imagem
            imagePositionX.value = 0.0;
            imagePositionY.value = 0.0;
            imageScale.value = 1.0;
            imageRotation.value = 0.0;
            rotationTextController.text = '0';

            // Inicializa transparência
            autoTransparencyValue.value = imageOpacity.value;
            _maxTransparencyValue = imageOpacity.value;

            // Carrega dimensões da primeira imagem
            await _loadImageDimensions();

            _autoSave();
          }
        }

        // Mostra mensagens sobre o resultado
        if (invalidImages.isNotEmpty) {
          Get.snackbar(
            'Imagens incompatíveis',
            'As seguintes imagens têm dimensões diferentes e não foram adicionadas:\n${invalidImages.join(', ')}',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
            maxWidth: 350,
          );
        }

        if (validImages.isNotEmpty) {
          Get.snackbar(
            'Imagens adicionadas',
            '${validImages.length} imagem(ns) adicionada(s) com sucesso',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao selecionar imagem: $e');
    }
  }

  void updateOpacity(double value) {
    imageOpacity.value = value;
    _autoSave();
  }

  void updatePosition(double x, double y) {
    // Só permite alteração de posição se o botão "Mover Imagem" estiver ativo
    if (!isImageMoveButtonActive.value) return;

    imagePositionX.value = x;
    imagePositionY.value = y;
    _autoSave();
  }

  void updateScale(double value) {
    // Só permite escala se o botão "Mover Imagem" estiver ativo
    if (!isImageMoveButtonActive.value) return;

    imageScale.value = value;
    _autoSave();
  }

  void updateRotation(double value) {
    // Só permite rotação se o botão "Mover Imagem" estiver ativo
    if (!isImageMoveButtonActive.value) return;

    imageRotation.value = value;
    // Atualiza o campo de texto sem triggar o listener
    rotationTextController.text = value.round().toString();
    _autoSave();
  }

  void updateRotationFromText(String text) {
    // Só permite rotação se o botão "Mover Imagem" estiver ativo
    if (!isImageMoveButtonActive.value) return;

    final double? value = double.tryParse(text);
    if (value != null) {
      // Normaliza o valor para ficar entre 0 e 360
      final normalizedValue = value % 360;
      imageRotation.value = normalizedValue < 0
          ? normalizedValue + 360
          : normalizedValue;
      _autoSave();
    }
  }

  void rotateImage(double degrees) {
    // Só permite rotação se o botão "Mover Imagem" estiver ativo
    if (!isImageMoveButtonActive.value) return;

    final newRotation = (imageRotation.value + degrees) % 360;
    imageRotation.value = newRotation;
    rotationTextController.text = newRotation.round().toString();
    _autoSave();
  } // Gesture handlers for ScaleGestureRecognizer (covers pan + scale)

  void onScaleStart(ScaleStartDetails details) {
    // No modo desenho, permite inicializar gestos de zoom e movimento mesmo sem o botão "Mover Imagem" ativo
    // No modo ajuste, só permite se o botão "Mover Imagem" estiver ativo

    _startFocalPoint = details.focalPoint;

    _initialCameraScale = cameraScale.value;
    _initialImageScale = imageScale.value;
    _initialCameraX = cameraPositionX.value;
    _initialCameraY = cameraPositionY.value;
    _initialImageX = imagePositionX.value;
    _initialImageY = imagePositionY.value;
    _initialImageRotation = imageRotation.value;
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    // No modo desenho, permite zoom e movimento mesmo sem o botão "Mover Imagem" ativo
    // No modo ajuste, só permite manipulação se o botão "Mover Imagem" estiver ativo

    double scaleChange = details.scale;
    double rotationChange = details.rotation;

    // Movimento
    final dx = details.focalPoint.dx - _startFocalPoint.dx;
    final dy = details.focalPoint.dy - _startFocalPoint.dy;

    // Debug: print focalPoint information
    print('focalPoint: ${details.focalPoint}');
    print('localFocalPoint: ${details.localFocalPoint}');
    print('focalPointDelta: ${details.focalPointDelta}');

    if (isDrawingMode) {
      cameraPositionX.value = dx + _initialCameraX;
      cameraPositionY.value = dy + _initialCameraY;
      imagePositionX.value = dx + _initialImageX;
      imagePositionY.value = dy + _initialImageY;

      cameraScale.value = _initialCameraScale * scaleChange;
      imageScale.value = _initialImageScale * scaleChange;
    } else if (isImageMoveButtonActive.value) {
      imagePositionX.value = dx + _initialImageX;
      imagePositionY.value = dy + _initialImageY;

      final newRotation = rotationChange + _initialImageRotation;
      final normalizedValue = newRotation % 360;
      imageRotation.value = normalizedValue < 0
          ? normalizedValue + 360
          : normalizedValue;

      imageScale.value = _initialImageScale * scaleChange;
    } else if (isCameraMoveButtonActive.value) {
      cameraPositionX.value = dx + _initialCameraX;
      cameraPositionY.value = dy + _initialCameraY;

      cameraScale.value = _initialCameraScale * scaleChange;
    }
  }

  void onScaleEnd(ScaleEndDetails details) {
    // No modo desenho, sempre salva as alterações de zoom e movimento
    // No modo ajuste, só salva se o botão "Mover Imagem" estiver ativo
    if (!isDrawingMode && !isImageMoveButtonActive.value) return;

    // Salva após terminar o gesto
    _autoSave();
  }

  void toggleOverlayVisibility(value) {
    showOverlayImage.value = value;
    _autoSave();
  }

  // Métodos de controle de zoom da câmera
  // OBS: _syncCameraZoomWithImage() foi removido, use _syncCameraZoomWithImageScale() que já existe

  Future<void> setCameraZoom(double zoom) async {
    if (cameraController.value != null && isCameraInitialized.value) {
      try {
        final clampedZoom = zoom.clamp(_minCameraZoom, _maxCameraZoom);
        // Atualiza imediatamente a variável observável para sincronização visual
        cameraZoom.value = clampedZoom;
        // Aplica o zoom na câmera de forma assíncrona sem bloquear
        cameraController.value!.setZoomLevel(clampedZoom).catchError((e) {
          print('Erro ao aplicar zoom da câmera: $e');
        });
      } catch (e) {
        print('Erro ao aplicar zoom da câmera: $e');
      }
    }
  }

  // Versão síncrona para uso durante gestos - evita delay
  void setCameraZoomSync(double zoom) {
    if (cameraController.value != null && isCameraInitialized.value) {
      final clampedZoom = zoom.clamp(_minCameraZoom, _maxCameraZoom);
      // Atualiza imediatamente a variável observável
      cameraZoom.value = clampedZoom;
      // Aplica o zoom na câmera sem await para evitar delay
      cameraController.value!.setZoomLevel(clampedZoom).catchError((e) {
        print('Erro ao aplicar zoom da câmera: $e');
      });
    }
  }

  void resetCameraZoom() {
    setCameraZoom(_minCameraZoom);
  }

  // Métodos de gerenciamento de projeto
  void loadProject(Project project) async {
    // Primeiro recarrega o projeto do storage para ter a versão mais recente
    final updatedProject = await _projectService.loadProject(project.id);
    final projectToLoad = updatedProject ?? project;

    currentProject.value = projectToLoad;

    // Carrega as configurações do projeto
    overlayImagePaths.value = projectToLoad.overlayImagePaths;
    currentImageIndex.value = projectToLoad.currentImageIndex;

    if (overlayImagePaths.isNotEmpty) {
      // Carrega dimensões da imagem quando carrega projeto
      _loadImageDimensions();
    }
    imageOpacity.value = projectToLoad.imageOpacity;
    imagePositionX.value = projectToLoad.imagePositionX;
    imagePositionY.value = projectToLoad.imagePositionY;
    imageScale.value = projectToLoad.imageScale;
    imageRotation.value = projectToLoad.imageRotation;
    showOverlayImage.value = projectToLoad.showOverlayImage;

    // Carrega posições da câmera
    cameraPositionX.value = projectToLoad.cameraPositionX;
    cameraPositionY.value = projectToLoad.cameraPositionY;
    cameraScale.value = projectToLoad.cameraScale;

    // Inicializa autoTransparencyValue com o valor da imageOpacity
    autoTransparencyValue.value = projectToLoad.imageOpacity;
    _maxTransparencyValue = projectToLoad.imageOpacity;

    // Atualiza o controller de texto
    rotationTextController.text = projectToLoad.imageRotation
        .toInt()
        .toString();
  }

  Future<void> saveCurrentProject() async {
    if (currentProject.value != null) {
      await _projectService.initialize();

      // Atualiza o projeto com as configurações atuais
      final updatedProject = currentProject.value!.copyWith(
        overlayImagePaths: overlayImagePaths.toList(),
        currentImageIndex: currentImageIndex.value,
        imageOpacity: imageOpacity.value,
        imagePositionX: imagePositionX.value,
        imagePositionY: imagePositionY.value,
        imageScale: imageScale.value,
        imageRotation: imageRotation.value,
        showOverlayImage: showOverlayImage.value,
        cameraPositionX: cameraPositionX.value,
        cameraPositionY: cameraPositionY.value,
        cameraScale: cameraScale.value,
        lastModified: DateTime.now(),
      );

      final success = await _projectService.saveProject(updatedProject);
      if (success) {
        currentProject.value = updatedProject;
      }
    }
  }

  // Auto-save a cada mudança importante
  void _autoSave() {
    if (currentProject.value != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        saveCurrentProject();
      });
    }
  }

  // Força salvamento imediato (sem delay)
  Future<void> forceSave() async {
    if (currentProject.value != null) {
      await saveCurrentProject();
    }
  }

  // Novos métodos para incluir auto-save
  void setImageOpacity(double value) {
    imageOpacity.value = value;
    _autoSave();
  }

  void updateImagePosition(double deltaX, double deltaY) {
    // Só permite alteração de posição se o botão "Mover Imagem" estiver ativo
    if (!isImageMoveButtonActive.value) return;

    imagePositionX.value += deltaX;
    imagePositionY.value += deltaY;
    _autoSave();
  }

  void updateImageScale(double scale) {
    // Só permite escala se o botão "Mover Imagem" estiver ativo
    if (!isImageMoveButtonActive.value) return;

    // Atualiza os valores da imagem (_adjustMode*)
    _adjustModeScale = scale;
    imageScale.value = scale;
    _updateCurrentDimensions(); // Atualiza dimensões quando escala mudar

    // Se estiver no modo desenho, também atualiza valores do modo desenho e sincroniza câmera
    if (isDrawingMode) {
      _drawingModeScale = scale;
      _syncCameraZoomWithImageScale(_drawingModeScale);
    }

    _autoSave();
  }

  void updateImageRotation(double rotation) {
    // Só permite rotação se o botão "Mover Imagem" estiver ativo
    if (!isImageMoveButtonActive.value) return;

    imageRotation.value = rotation;
    rotationTextController.text = rotation.toInt().toString();
    _autoSave();
  }

  void resetImageTransform() {
    // Reset dos valores da imagem (_adjustMode*)
    _adjustModePositionX = 0.0;
    _adjustModePositionY = 0.0;
    _adjustModeScale = 1.0;

    imagePositionX.value = 0.0;
    imagePositionY.value = 0.0;
    imageScale.value = 1.0;
    imageRotation.value = 0.0;
    imageOpacity.value = 0.5;
    rotationTextController.text = '0';

    // Reset dos valores do modo desenho (_drawingMode*)
    _drawingModePositionX = 0.0;
    _drawingModePositionY = 0.0;
    _drawingModeScale = 1.0;

    // Reset das posições da câmera
    cameraPositionX.value = 0.0;
    cameraPositionY.value = 0.0;

    // Reseta zoom da câmera usando valores do modo desenho
    _syncCameraZoomWithImageScale(_drawingModeScale);

    // Reset da transparência automática
    autoTransparencyValue.value = 0.5;
    _maxTransparencyValue = 0.5;

    _autoSave();
  }

  // Carrega as dimensões da imagem selecionada
  Future<void> _loadImageDimensions() async {
    if (selectedImagePath.isNotEmpty) {
      try {
        final imageFile = File(selectedImagePath);
        final imageBytes = await imageFile.readAsBytes();
        final image = await decodeImageFromList(imageBytes);

        originalImageWidth.value = image.width.toDouble();
        originalImageHeight.value = image.height.toDouble();

        // Calcula dimensões atuais baseadas na escala
        _updateCurrentDimensions();

        // Atualiza os controllers
        imageWidthController.text = currentImageWidth.value.round().toString();
        imageHeightController.text = currentImageHeight.value
            .round()
            .toString();

        image.dispose();
      } catch (e) {
        print('Erro ao carregar dimensões da imagem: $e');
      }
    }
  }

  // Atualiza as dimensões atuais baseadas na escala
  void _updateCurrentDimensions() {
    if (originalImageWidth.value > 0 && originalImageHeight.value > 0) {
      currentImageWidth.value = originalImageWidth.value * imageScale.value;
      currentImageHeight.value = originalImageHeight.value * imageScale.value;
    }
  }

  // Aplica novas dimensões ajustando a escala
  void applyImageDimensions(int width, int height) {
    // Só permite alteração de dimensões se o botão "Mover Imagem" estiver ativo
    if (!isImageMoveButtonActive.value) return;

    if (originalImageWidth.value > 0 && originalImageHeight.value > 0) {
      // Calcula a escala baseada na largura (prioritária)
      final newScale = width / originalImageWidth.value;

      print(
        'Aplicando dimensões: ${width} x ${height}, nova escala: ${newScale}',
      );

      // Aplica a nova escala
      imageScale.value = newScale.clamp(0.1, 10.0);

      // Atualiza dimensões atuais
      _updateCurrentDimensions();

      // Atualiza controllers para refletir as dimensões reais
      imageWidthController.text = currentImageWidth.value.round().toString();
      imageHeightController.text = currentImageHeight.value.round().toString();

      _autoSave();
    } else {
      print('Erro: Dimensões originais não carregadas');
    }
  }

  // Exibe modal para ajuste fino de dimensões
  Future<void> showDimensionsModal() async {
    if (selectedImagePath.isEmpty) {
      Get.snackbar('Erro', 'Selecione uma imagem primeiro');
      return;
    }

    // Carrega dimensões se ainda não foram carregadas
    if (originalImageWidth.value == 0 || originalImageHeight.value == 0) {
      await _loadImageDimensions();
    }

    // Atualiza dimensões atuais
    _updateCurrentDimensions();
    imageWidthController.text = currentImageWidth.value.round().toString();
    imageHeightController.text = currentImageHeight.value.round().toString();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Obx(
          () => Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                Row(
                  children: [
                    Icon(Icons.photo_size_select_large, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Ajuste Fino de Dimensões',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Informações da imagem original
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Dimensões Originais',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${originalImageWidth.value.round()} × ${originalImageHeight.value.round()} px',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Campos de entrada
                Row(
                  children: [
                    // Largura
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Largura (px)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 6),
                          TextField(
                            controller: imageWidthController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                              filled: true,
                              fillColor: Colors.grey.withValues(alpha: 0.1),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    // Altura
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Altura (px)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 6),
                          TextField(
                            controller: imageHeightController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                              filled: true,
                              fillColor: Colors.grey.withValues(alpha: 0.1),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Botões
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final width = int.tryParse(imageWidthController.text);
                          final height = int.tryParse(
                            imageHeightController.text,
                          );

                          if (width != null &&
                              height != null &&
                              width > 0 &&
                              height > 0) {
                            applyImageDimensions(width, height);
                            Get.back();
                            Get.snackbar(
                              'Sucesso',
                              'Dimensões aplicadas: ${width} × ${height} px',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green.withValues(
                                alpha: 0.8,
                              ),
                              colorText: Colors.white,
                            );
                          } else {
                            Get.snackbar(
                              'Erro',
                              'Digite valores válidos para largura e altura',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red.withValues(
                                alpha: 0.8,
                              ),
                              colorText: Colors.white,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Aplicar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ), // Fechamento do Obx
      ),
    );
  }

  // Métodos para transparência automática
  void toggleAutoTransparency() {
    isAutoTransparencyEnabled.value = !isAutoTransparencyEnabled.value;
    if (isAutoTransparencyEnabled.value) {
      _startAutoTransparencyAnimation();
    } else {
      _stopAutoTransparencyAnimation();
    }
  }

  void _startAutoTransparencyAnimation() {
    if (!isDrawingMode) return; // Só funciona no modo desenho

    _maxTransparencyValue = imageOpacity.value; // Salva o valor atual do slider
    _animateTransparency();
  }

  void _stopAutoTransparencyAnimation() {
    // Restaura a transparência para o valor definido no slider
    autoTransparencyValue.value = _maxTransparencyValue;
  }

  void _animateTransparency() async {
    if (!isAutoTransparencyEnabled.value || !isDrawingMode) return;

    // Anima de 0 até o valor máximo
    for (
      double opacity = 0.0;
      opacity <= _maxTransparencyValue;
      opacity += 0.02
    ) {
      if (!isAutoTransparencyEnabled.value || !isDrawingMode) break;
      autoTransparencyValue.value = opacity;
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Anima do valor máximo até 0
    for (
      double opacity = _maxTransparencyValue;
      opacity >= 0.0;
      opacity -= 0.02
    ) {
      if (!isAutoTransparencyEnabled.value || !isDrawingMode) break;
      autoTransparencyValue.value = opacity;
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Repete a animação
    if (isAutoTransparencyEnabled.value && isDrawingMode) {
      _animateTransparency();
    }
  }

  // Método helper para obter dimensões de uma imagem
  Future<Size?> _getImageDimensions(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) return null;

      final bytes = await imageFile.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      return Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );
    } catch (e) {
      print('Erro ao obter dimensões da imagem: $e');
      return null;
    }
  }

  // Verifica se duas imagens têm dimensões compatíveis (tolerância de 5%)
  bool _areImageDimensionsCompatible(Size size1, Size size2) {
    const double tolerance = 0.05; // 5% de tolerância

    final double widthDiff = (size1.width - size2.width).abs() / size1.width;
    final double heightDiff =
        (size1.height - size2.height).abs() / size1.height;

    return widthDiff <= tolerance && heightDiff <= tolerance;
  }

  // Valida se uma nova imagem é compatível com as existentes
  Future<bool> _validateImageCompatibility(String newImagePath) async {
    if (overlayImagePaths.isEmpty)
      return true; // Primeira imagem sempre é válida

    final newImageSize = await _getImageDimensions(newImagePath);
    if (newImageSize == null) return false;

    // Verifica compatibilidade com a primeira imagem da lista
    final firstImageSize = await _getImageDimensions(overlayImagePaths.first);
    if (firstImageSize == null) return false;

    return _areImageDimensionsCompatible(firstImageSize, newImageSize);
  }

  // Atualiza o valor máximo quando o slider de transparência muda
  void updateImageOpacity(double value) {
    imageOpacity.value = value;
    _maxTransparencyValue = value;

    // Se não está em modo auto, atualiza a transparência atual
    if (!isAutoTransparencyEnabled.value) {
      autoTransparencyValue.value = value;
    }

    _autoSave();
  }
}

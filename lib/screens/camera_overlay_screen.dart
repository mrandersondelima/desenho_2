import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/camera_controller.dart';
import '../models/project.dart';

class CameraOverlayScreen extends StatelessWidget {
  final Project? project;
  final CameraOverlayController controller = Get.put(CameraOverlayController());

  CameraOverlayScreen({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    // Carrega o projeto se fornecido
    if (project != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadProject(project!);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white10,
      body: Stack(
        children: [
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            return Container();
          }),

          Obx(() {
            if (!controller.isCameraInitialized.value ||
                controller.cameraController.value == null) {
              return const Center(
                child: Text(
                  'Erro ao inicializar câmera',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            return Container();
          }),

          // GestureDetector global para capturar todos os gestos (pinch, pan, etc)
          // Deve estar ACIMA da câmera e imagem para capturar gestos que tocam ambos
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: controller.onScaleStart,
              onScaleUpdate: controller.onScaleUpdate,
              onScaleEnd: controller.onScaleEnd,
              behavior: HitTestBehavior
                  .translucent, // Permite que gestos passem através quando não consumidos
              child: Container(
                color: Colors.transparent,
              ), // Container transparente para capturar gestos
            ),
          ),

          // Fundo branco
          Positioned.fill(
            child: IgnorePointer(
              // Ignora toques para não interferir com GestureDetector global
              child: Container(color: Colors.white),
            ),
          ),

          // câmera
          Obx(() {
            if (controller.isCameraInitialized.value &&
                controller.cameraController.value != null) {
              return Positioned.fill(
                child: IgnorePointer(
                  // Ignora toques para não interferir com GestureDetector global
                  child: Transform.translate(
                    offset: Offset(
                      controller.cameraPositionX.value,
                      controller.cameraPositionY.value,
                    ),
                    child: Transform.scale(
                      scale: controller.cameraScale.value,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller
                              .cameraController
                              .value!
                              .value
                              .previewSize!
                              .height,
                          height: controller
                              .cameraController
                              .value!
                              .value
                              .previewSize!
                              .width,
                          child: CameraPreview(
                            controller.cameraController.value!,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return Container();
            }
          }),

          // Imagem de sobreposição
          Obx(() {
            if (controller.hasOverlayImages &&
                controller.showOverlayImage.value) {
              return Positioned.fill(
                child: IgnorePointer(
                  // Ignora toques para não interferir com GestureDetector global
                  child: Transform.translate(
                    offset: Offset(
                      controller.imagePositionX.value,
                      controller.imagePositionY.value,
                    ),
                    child: Transform.scale(
                      scale: controller.imageScale.value,
                      child: Transform.rotate(
                        angle: controller
                            .imageRotation
                            .value, // Converte graus para radianos
                        child: Opacity(
                          opacity: controller.autoTransparencyValue.value,
                          child: Center(
                            child: Image.file(
                              File(controller.selectedImagePath),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            return Container();
          }),

          Obx(() {
            if (controller.areControlsVisible.value) {
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botão Voltar
                        _buildToolbarButton(
                          label: 'Voltar',
                          isActive: false,
                          onPressed: () async {
                            // Força salvamento antes de voltar
                            await controller.forceSave();
                            Get.back();
                          },
                        ),
                        _buildToolbarButton(
                          label: 'Reiniciar',
                          isActive: false,
                          onPressed: () {
                            controller.confirmAndResetImageTransform();
                          },
                        ),
                        // Botão Ferramentas
                        _buildToolbarButton(
                          label: 'Ferramentas',
                          isActive: controller.isToolsButtonActive.value,
                          onPressed: () {
                            controller.toggleToolsButton();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Container();
          }),

          // Barra secundária superior (ferramentas)
          Obx(
            () => controller.areControlsVisible.value
                ? Visibility(
                    visible: controller.isToolsBarExpanded.value,
                    child: Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            children: [
                              // Botão Camadas
                              _buildToolbarButton(
                                label: 'Camadas',
                                isActive:
                                    controller.isVisibilityButtonActive.value,
                                onPressed: () {
                                  controller.toggleVisibilityButton();
                                },
                              ),
                              // Botão Piscar
                              _buildToolbarButton(
                                label: 'Piscar',
                                isActive: controller.isFlashButtonActive.value,
                                onPressed: () {
                                  controller.toggleFlashButton();
                                },
                              ),

                              // Botão Iluminação
                              _buildToolbarButton(
                                label: 'Iluminação',
                                isActive:
                                    controller.isIlluminationButtonActive.value,
                                onPressed: () {
                                  controller.toggleIlluminationButton();
                                },
                              ),

                              _buildToolbarButton(
                                label: 'Ângulo',
                                isActive: controller.isAngleButtonActive.value,
                                onPressed: () {
                                  controller.toggleAngleButton();
                                },
                              ),

                              _buildToolbarButton(
                                label: 'Escala',
                                isActive: controller.isScaleButtonActive.value,
                                onPressed: () {
                                  controller.toggleScaleButton();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
          ),

          Obx(
            () => !controller.areControlsVisible.value
                ? Positioned(
                    top: 0, // Logo abaixo da barra superior
                    left: 16,
                    child: SafeArea(
                      child: GestureDetector(
                        onTap: () {
                          controller.areControlsVisible.value = true;
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
          ),

          // Barra do botão Camadas deslizante (seleção de imagens) - aparece abaixo da barra de ferramentas
          Obx(
            () => controller.areControlsVisible.value
                ? Visibility(
                    visible: controller.isVisibilityBarExpanded.value,
                    child: Positioned(
                      top:
                          90, // 50 (barra principal) + 40 (barra secundária) + 40 (barra piscar) + 40 (barra ângulo)
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Container(
                          height:
                              90, // Altura um pouco maior para acomodar a lista de imagens
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.layers,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: controller.overlayImages.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'Nenhuma imagem carregada',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount:
                                              controller.overlayImages.length,
                                          itemBuilder: (context, index) {
                                            bool isSelected =
                                                controller
                                                    .currentImageIndex
                                                    .value ==
                                                index;
                                            final image =
                                                controller.overlayImages[index];
                                            return GestureDetector(
                                              onTap: () => controller
                                                  .selectImageByIndex(index),
                                              onLongPress: () => controller
                                                  .editImageTitle(index),
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  right: 12,
                                                ),
                                                width: 70,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 60,
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color: isSelected
                                                              ? Colors.blue
                                                              : Colors.grey,
                                                          width: isSelected
                                                              ? 2
                                                              : 1,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                            child: Image.file(
                                                              File(image.path),
                                                              fit: BoxFit.cover,
                                                              width: 60,
                                                              height: 60,
                                                            ),
                                                          ),
                                                          // Botões de reordenar
                                                          if (isSelected)
                                                            Positioned(
                                                              top: 0,
                                                              right: 0,
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  if (index > 0)
                                                                    GestureDetector(
                                                                      onTap: () =>
                                                                          controller.moveImageUp(
                                                                            index,
                                                                          ),
                                                                      child: Container(
                                                                        width:
                                                                            20,
                                                                        height:
                                                                            20,
                                                                        decoration: BoxDecoration(
                                                                          color: Colors.blue.withValues(
                                                                            alpha:
                                                                                0.8,
                                                                          ),
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: const Icon(
                                                                          Icons
                                                                              .arrow_back,
                                                                          size:
                                                                              12,
                                                                          color:
                                                                              Colors.white,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  const SizedBox(
                                                                    width: 2,
                                                                  ),
                                                                  if (index <
                                                                      controller
                                                                              .overlayImages
                                                                              .length -
                                                                          1)
                                                                    GestureDetector(
                                                                      onTap: () =>
                                                                          controller.moveImageDown(
                                                                            index,
                                                                          ),
                                                                      child: Container(
                                                                        width:
                                                                            20,
                                                                        height:
                                                                            20,
                                                                        decoration: BoxDecoration(
                                                                          color: Colors.blue.withValues(
                                                                            alpha:
                                                                                0.8,
                                                                          ),
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: const Icon(
                                                                          Icons
                                                                              .arrow_forward,
                                                                          size:
                                                                              12,
                                                                          color:
                                                                              Colors.white,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      image.title,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: isSelected
                                                            ? Colors.blue
                                                            : Colors.black87,
                                                        fontSize: 10,
                                                        fontWeight: isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                Text(
                                  '${controller.currentImageIndex.value + 1}/${controller.overlayImages.length}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
          ),

          Obx(
            () => Visibility(
              visible:
                  controller.isMoveBarExpanded.value &&
                  controller.areControlsVisible.value,
              child: Positioned(
                bottom: controller.isMoveBarExpanded.value ? 50 : -30,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildToolbarButton(
                          label: "Imagem",
                          isActive: controller.isImageMoveButtonActive.value,
                          onPressed: () {
                            controller.toggleMoveImageButton();
                          },
                        ),
                        _buildToolbarButton(
                          label: "Câmera",
                          isActive: controller.isCameraMoveButtonActive.value,
                          onPressed: () {
                            controller.toggleMoveCameraButton();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Barra de opacidade deslizante
          Obx(
            () => Visibility(
              visible:
                  controller.isOpacityBarExpanded.value &&
                  controller.areControlsVisible.value,
              child: Positioned(
                bottom: controller.isOpacityBarExpanded.value ? 50 : -30,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: controller.imageOpacity.value,
                              min: 0.0,
                              max: 1.0,
                              activeColor: Colors.blue,
                              inactiveColor: Colors.grey,
                              onChanged: controller.updateImageOpacity,
                            ),
                          ),
                          Text(
                            '${(controller.imageOpacity.value * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch.adaptive(
                            value: controller.isOpacitySwitchEnabled.value,
                            onChanged: (value) {
                              controller.toggleOverlayVisibility(value);
                              controller.isOpacitySwitchEnabled.value = value;
                            },
                            activeTrackColor: Colors.blue,
                            activeThumbColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Barra do botão Piscar deslizante (auto transparência) - aparece abaixo da barra de ferramentas
          Obx(
            () => controller.areControlsVisible.value
                ? Visibility(
                    visible: controller.isFlashBarExpanded.value,
                    child: Positioned(
                      top: 90, // 50 (barra principal) + 40 (barra secundária)
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Row(
                              children: [
                                // Só mostra o switch se estiver no modo desenho
                                Obx(
                                  () => Switch.adaptive(
                                    value:
                                        !controller
                                            .isImageMoveButtonActive
                                            .value
                                        ? controller
                                              .isAutoTransparencyEnabled
                                              .value
                                        : false,
                                    onChanged:
                                        !controller
                                            .isImageMoveButtonActive
                                            .value
                                        ? (value) => controller
                                              .toggleAutoTransparency()
                                        : null,
                                    activeTrackColor: Colors.blue,
                                    activeThumbColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Indicador de modo
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
          ),

          // Barra do botão Ângulo - aparece abaixo da barra de ferramentas
          Obx(
            () => controller.areControlsVisible.value
                ? Visibility(
                    visible: controller.isAngleBarExpanded.value,
                    child: Positioned(
                      top:
                          90, // 50 (barra principal) + 40 (barra secundária) + 40 (barra piscar)
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Botão diminuir (-)
                                GestureDetector(
                                  onTapDown: (_) =>
                                      controller.startRotatingImage(false),
                                  onTapUp: (_) =>
                                      controller.stopRotatingImage(),
                                  onTapCancel: () =>
                                      controller.stopRotatingImage(),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.orange,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.remove,
                                      color: Colors.orange,
                                      size: 32,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 24),

                                // Texto indicador
                                Obx(
                                  () => Container(
                                    width: 70,
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      child: Text(
                                        '${(controller.imageRotation.value * 57.2958).toPrecision(2)}°',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 24),

                                // Botão aumentar (+)
                                GestureDetector(
                                  onTapDown: (_) =>
                                      controller.startRotatingImage(true),
                                  onTapUp: (_) =>
                                      controller.stopRotatingImage(),
                                  onTapCancel: () =>
                                      controller.stopRotatingImage(),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.blue,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.blue,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
          ),

          // Barra do botão Escala - aparece abaixo da barra de ângulo
          Obx(
            () => controller.areControlsVisible.value
                ? Visibility(
                    visible: controller.isScaleBarExpanded.value,
                    child: Positioned(
                      top:
                          90, // 50 (barra principal) + 40 (barra secundária) + 40 (barra piscar) + 40 (barra ângulo) + 40 (barra escala)
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Botão diminuir (-)
                                GestureDetector(
                                  onTapDown: (_) =>
                                      controller.startScalingImage(false),
                                  onTapUp: (_) => controller.stopScalingImage(),
                                  onTapCancel: () =>
                                      controller.stopScalingImage(),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.remove,
                                      color: Colors.red,
                                      size: 32,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Texto indicador
                                Obx(
                                  () => Text(
                                    '${(controller.imageScale.value * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Botão aumentar (+)
                                GestureDetector(
                                  onTapDown: (_) =>
                                      controller.startScalingImage(true),
                                  onTapUp: (_) => controller.stopScalingImage(),
                                  onTapCancel: () =>
                                      controller.stopScalingImage(),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.green,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
          ),

          // Controle direcional - aparece quando "Mover Imagem" está ativo
          Obx(
            () =>
                controller.isImageMoveButtonActive.value &&
                    controller.areControlsVisible.value
                ? Positioned(
                    bottom: 100, // Logo acima da barra de ferramentas inferior
                    right: 20,
                    child: SafeArea(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Seta para cima
                            Positioned(
                              top: 0,
                              left: 40,
                              child: GestureDetector(
                                onTapDown: (_) =>
                                    controller.startMovingImage('up'),
                                onTapUp: (_) => controller.stopMovingImage(),
                                onTapCancel: () => controller.stopMovingImage(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            // Seta para baixo
                            Positioned(
                              bottom: 0,
                              left: 40,
                              child: GestureDetector(
                                onTapDown: (_) =>
                                    controller.startMovingImage('down'),
                                onTapUp: (_) => controller.stopMovingImage(),
                                onTapCancel: () => controller.stopMovingImage(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_downward,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            // Seta para esquerda
                            Positioned(
                              top: 40,
                              left: 0,
                              child: GestureDetector(
                                onTapDown: (_) =>
                                    controller.startMovingImage('left'),
                                onTapUp: (_) => controller.stopMovingImage(),
                                onTapCancel: () => controller.stopMovingImage(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            // Seta para direita
                            Positioned(
                              top: 40,
                              right: 0,
                              child: GestureDetector(
                                onTapDown: (_) =>
                                    controller.startMovingImage('right'),
                                onTapUp: (_) => controller.stopMovingImage(),
                                onTapCancel: () => controller.stopMovingImage(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            // Centro (opcional - pode ser usado para centralizar)
                            Positioned(
                              top: 40,
                              left: 40,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Container(),
          ),

          // Navegação entre camadas - aparece no modo desenho quando controles estão ocultos
          Obx(
            () =>
                controller.isDrawingMode &&
                    !controller.areControlsVisible.value &&
                    controller.overlayImages.length > 1
                ? Positioned(
                    bottom:
                        20, // Mais para baixo já que controles estão ocultos
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Container(
                        height: 60,
                        color: Colors.black.withValues(alpha: 0.3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Seta esquerda (camada anterior)
                            GestureDetector(
                              onTap: () => controller.goToPreviousLayer(),
                              child: Container(
                                width: 80,
                                height: 62,
                                color: Colors.transparent,
                                child: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),

                            // Indicador da camada atual
                            Obx(
                              () => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  controller.selectedImage?.title ??
                                      'Sem título',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            // Seta direita (próxima camada)
                            GestureDetector(
                              onTap: () => controller.goToNextLayer(),
                              child: Container(
                                width: 80,
                                height: 60,
                                color: Colors.transparent,
                                child: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Container(),
          ),

          // Barra de ferramentas inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(
              () => controller.areControlsVisible.value
                  ? SafeArea(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Botão Mover
                            Obx(
                              () => _buildToolbarButton(
                                label: 'Mover',
                                isActive: controller.isMoveButtonActive.value,
                                onPressed: () {
                                  controller.toggleMoveButton();
                                  controller.isMoveBarExpanded.value =
                                      !controller.isMoveBarExpanded.value;
                                },
                              ),
                            ),

                            // Botão Esconder
                            _buildToolbarButton(
                              label: 'Esconder',
                              onPressed: () {
                                controller.toggleHideButton();
                                controller.toggleVisibility();
                              },
                            ),

                            // Botão Opacidade
                            Obx(
                              () => _buildToolbarButton(
                                label: 'Opacidade',
                                isActive:
                                    controller.isOpacityButtonActive.value,
                                onPressed: () {
                                  controller.toggleOpacityButton();
                                  controller.isOpacityBarExpanded.value =
                                      !controller.isOpacityBarExpanded.value;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.blue : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

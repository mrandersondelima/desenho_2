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

          Positioned.fill(
            child: GestureDetector(
              onScaleStart: controller.isDrawingMode
                  ? controller.onScaleStart
                  : null,
              onScaleUpdate: controller.isDrawingMode
                  ? controller.onScaleUpdate
                  : null,
              onScaleEnd: controller.isDrawingMode
                  ? controller.onScaleEnd
                  : null,
              child: Container(color: Colors.white),
            ),
          ),

          // câmera
          Obx(() {
            if (controller.isCameraInitialized.value &&
                controller.cameraController.value != null) {
              return Positioned.fill(
                child: GestureDetector(
                  onScaleStart:
                      controller.isCameraMoveButtonActive.value ||
                          controller.isDrawingMode
                      ? controller.onScaleStart
                      : null,
                  onScaleUpdate:
                      controller.isCameraMoveButtonActive.value ||
                          controller.isDrawingMode
                      ? controller.onScaleUpdate
                      : null,
                  onScaleEnd:
                      controller.isCameraMoveButtonActive.value ||
                          controller.isDrawingMode
                      ? controller.onScaleEnd
                      : null,
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

          Obx(() {
            if (controller.hasOverlayImages &&
                controller.showOverlayImage.value) {
              return Positioned.fill(
                child: GestureDetector(
                  onScaleStart: controller.onScaleStart,
                  onScaleUpdate: controller.onScaleUpdate,
                  onScaleEnd: controller.onScaleEnd,
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
                            controller.resetImageTransform();
                          },
                        ),
                        // Botão Ferramentas
                        _buildToolbarButton(
                          label: 'Ferramentas',
                          isActive: controller.isToolsButtonActive.value,
                          onPressed: () {
                            controller.toggleToolsButton();
                            controller.isToolsBarExpanded.value =
                                !controller.isToolsBarExpanded.value;
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

                              // Botão Camadas
                              _buildToolbarButton(
                                label: 'Camadas',
                                isActive:
                                    controller.isVisibilityButtonActive.value,
                                onPressed: () {
                                  controller.toggleVisibilityButton();
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
                              60, // Altura um pouco maior para acomodar a lista de imagens
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
                                  child: controller.overlayImagePaths.isEmpty
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
                                          itemCount: controller
                                              .overlayImagePaths
                                              .length,
                                          itemBuilder: (context, index) {
                                            bool isSelected =
                                                controller
                                                    .currentImageIndex
                                                    .value ==
                                                index;
                                            return GestureDetector(
                                              onTap: () => controller
                                                  .selectImageByIndex(index),
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  right: 8,
                                                ),
                                                width: 45,
                                                height: 45,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? Colors.blue
                                                        : Colors.grey,
                                                    width: isSelected ? 2 : 1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: Image.file(
                                                    File(
                                                      controller
                                                          .overlayImagePaths[index],
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                Text(
                                  '${controller.currentImageIndex.value + 1}/${controller.overlayImagePaths.length}',
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

          // Barra de opacidade deslizante
          Obx(
            () => Visibility(
              visible: controller.isOpacityBarExpanded.value,
              child: Positioned(
                bottom: controller.isOpacityBarExpanded.value ? 50 : -30,
                left: 0,
                right: 0,
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
                          activeColor: Colors.blue,
                        ),
                      ],
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
                                    activeColor: Colors.blue,
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

          // Barra do botão Ângulo deslizante (controles de rotação) - aparece abaixo da barra de ferramentas
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
                          height:
                              100, // Altura maior para acomodar slider e input
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
                              vertical: 8.0,
                            ),
                            child: Column(
                              children: [
                                // Slider de rotação
                                Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: controller.imageRotation.value,
                                        min: 0.0,
                                        max: 360.0,
                                        activeColor: Colors.blue,
                                        inactiveColor: Colors.grey,
                                        onChanged: controller.updateRotation,
                                      ),
                                    ),
                                    Text(
                                      '${controller.imageRotation.value.round()}°',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                // Input de ângulo
                                Row(
                                  children: [
                                    const Text(
                                      'Ângulo:',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        height: 30,
                                        child: TextField(
                                          controller:
                                              controller.rotationTextController,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                color: Colors.blue,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                color: Colors.blue,
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                color: Colors.blue,
                                                width: 2,
                                              ),
                                            ),
                                            suffixText: '°',
                                            suffixStyle: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          onSubmitted:
                                              controller.updateRotationFromText,
                                          onChanged:
                                              controller.updateRotationFromText,
                                        ),
                                      ),
                                    ),
                                  ],
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

          // Barra de ferramentas inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(
              () => controller.areControlsVisible.value
                  ? Container(
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
                          Obx(
                            () => _buildToolbarButton(
                              label: 'Esconder',
                              isActive: controller.isHideButtonActive.value,
                              onPressed: () {
                                controller.toggleHideButton();
                                controller.toggleVisibility();
                              },
                            ),
                          ),

                          // Botão Opacidade
                          Obx(
                            () => _buildToolbarButton(
                              label: 'Opacidade',
                              isActive: controller.isOpacityButtonActive.value,
                              onPressed: () {
                                controller.toggleOpacityButton();
                                controller.isOpacityBarExpanded.value =
                                    !controller.isOpacityBarExpanded.value;
                              },
                            ),
                          ),
                        ],
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

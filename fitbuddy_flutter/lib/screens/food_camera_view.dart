import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../models/food_entry.dart';

class FoodCameraView extends StatefulWidget {
  const FoodCameraView({super.key});

  @override
  State<FoodCameraView> createState() => _FoodCameraViewState();
}

class _FoodCameraViewState extends State<FoodCameraView> {
  final CameraService _cameraService = CameraService();
  bool _isLoading = false;
  bool _isAnalyzing = false;
  FoodEntry? _analyzedFood;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _cameraService.initialize();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_cameraService.isInitialized && _cameraService.controller != null)
              CameraPreview(_cameraService.controller!)
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            
            // Camera Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery Button
                    IconButton(
                      onPressed: _isLoading ? null : _pickFromGallery,
                      icon: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    
                    // Capture Button
                    GestureDetector(
                      onTap: _isLoading ? null : _takePicture,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.white.withOpacity(0.3),
                        ),
                        child: const Icon(
                          Icons.camera,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    
                    // Close Button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Loading Overlay
            if (_isLoading || _isAnalyzing)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        _isAnalyzing ? 'Analyzing food...' : 'Loading camera...',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Analysis Result
            if (_analyzedFood != null)
              _buildAnalysisResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Food Analysis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _analyzedFood = null;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Food Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food Name
                      Text(
                        _analyzedFood!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Calories
                      _buildNutritionCard(
                        'Calories',
                        '${_analyzedFood!.calories.toInt()}',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Macros
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutritionCard(
                              'Protein',
                              '${_analyzedFood!.protein.toInt()}g',
                              Icons.fitness_center,
                              Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildNutritionCard(
                              'Carbs',
                              '${_analyzedFood!.carbs.toInt()}g',
                              Icons.grain,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildNutritionCard(
                              'Fat',
                              '${_analyzedFood!.fat.toInt()}g',
                              Icons.water_drop,
                              Colors.yellow,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _saveFoodEntry(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Save Food'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _editFoodEntry(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Edit'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_isLoading) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final imageFile = await _cameraService.takePicture();
      if (imageFile != null) {
        final foodEntry = await _cameraService.analyzeFoodImage(imageFile);
        setState(() {
          _analyzedFood = foodEntry;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: $e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isLoading) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final imageFile = await _cameraService.pickImageFromGallery();
      if (imageFile != null) {
        final foodEntry = await _cameraService.analyzeFoodImage(imageFile);
        setState(() {
          _analyzedFood = foodEntry;
          _isAnalyzing = false;
        });
      } else {
        setState(() {
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _saveFoodEntry() {
    if (_analyzedFood != null) {
      // TODO: Save to storage service
      Navigator.pop(context, _analyzedFood);
    }
  }

  void _editFoodEntry() {
    // TODO: Navigate to food editing screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature coming soon!')),
    );
  }
} 
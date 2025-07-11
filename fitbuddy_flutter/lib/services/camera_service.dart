import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ai_service.dart';
import '../models/food_entry.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  Future<void> initialize() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Camera permission denied');
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      // Initialize camera controller
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing camera: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _isInitialized = false;
  }

  Future<File?> takePicture() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    try {
      final XFile image = await _controller!.takePicture();
      return File(image.path);
    } catch (e) {
      print('Error taking picture: $e');
      rethrow;
    }
  }

  Future<File?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      rethrow;
    }
  }

  Future<FoodEntry?> analyzeFoodImage(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Use AI service to analyze the image
      final aiService = AIService();
      final response = await aiService.analyzeFoodImage(base64Image);

      if (response != null) {
        return _parseFoodAnalysis(response);
      }
      return null;
    } catch (e) {
      print('Error analyzing food image: $e');
      rethrow;
    }
  }

  FoodEntry _parseFoodAnalysis(String analysis) {
    try {
      // Try to parse JSON response
      final json = jsonDecode(analysis);
      
      return FoodEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['name'] ?? 'Unknown Food',
        calories: (json['calories'] ?? 0).toDouble(),
        protein: (json['protein'] ?? 0).toDouble(),
        carbs: (json['carbs'] ?? 0).toDouble(),
        fat: (json['fat'] ?? 0).toDouble(),
        fiber: (json['fiber'] ?? 0).toDouble(),
        sugar: (json['sugar'] ?? 0).toDouble(),
        sodium: (json['sodium'] ?? 0).toDouble(),
        servingSize: 1.0,
        servingUnit: 'serving',
        date: DateTime.now(),
        mealType: 'snacks',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      // Fallback to manual entry if JSON parsing fails
      return FoodEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Food from Image',
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        sugar: 0,
        sodium: 0,
        servingSize: 1.0,
        servingUnit: 'serving',
        date: DateTime.now(),
        mealType: 'snacks',
        createdAt: DateTime.now(),
      );
    }
  }
} 
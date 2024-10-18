import 'dart:io';
import 'dart:math';
import 'package:admin/models/api_response.dart';
import 'package:admin/utility/snack_bar_helper.dart';

import '../../../services/http_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/data/data_provider.dart';
import '../../../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  HttpService service = HttpService();
  final DataProvider _dataProvider;
  final addCategoryFormKey = GlobalKey<FormState>();
  TextEditingController categoryNameCtrl = TextEditingController();
  Category? categoryForUpdate;

  File? selectedImage;
  XFile? imgXFile;

  CategoryProvider(this._dataProvider);

  //? Pick an image from the gallery
  void pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage = File(image.path);
      imgXFile = image;
      notifyListeners();
    }
  }

  //? Add a new category
  addCategory() async {
    try {
      if (selectedImage == null) {
        SnackBarHelper.showErrorSnackBar('Please choose an image');
        return;
      }
      Map<String, dynamic> formData = {
        'name': categoryNameCtrl.text,
        'image': 'no_data',
      };
      final FormData form = await createFormData(imgXFile: imgXFile, formData: formData);
      final response = await service.addItem(endpointUrl: 'categories', itemData: form);
      if (response.isOk) {
        ApiResponse apiResponse = ApiResponse.fromJson(response.body, null);
        if (apiResponse.success) {
          clearFields();
          SnackBarHelper.showSuccessSnackBar(apiResponse.message);
          _dataProvider.getAllCategories();
        } else {
          SnackBarHelper.showErrorSnackBar(apiResponse.message);
        }
      }
    } catch (e) {
      print(e);
      SnackBarHelper.showErrorSnackBar('An error occurred: $e');
      rethrow;
    }
  }

  // //? Update an existing category
  updateCategory() async {
    try {
      Map<String , dynamic> formData = {
        'name': categoryNameCtrl.text,
        'image':categoryForUpdate?.image ?? '',
      };

      final FormData form = await createFormData(imgXFile: imgXFile, formData: formData);
      final response = await service.updateItem(
        endpointUrl: 'categories',
        itemData: form,
        itemId: categoryForUpdate?.sId ?? '',
      );

      if (response.isOk) {
        ApiResponse apiResponse = ApiResponse.fromJson(response.body, null);
        if (apiResponse.success) {
          clearFields();
          SnackBarHelper.showSuccessSnackBar(apiResponse.message);
          _dataProvider.getAllCategories();
        } else {
          SnackBarHelper.showErrorSnackBar(apiResponse.message);
        }
      }
    } catch (e) {
      print(e);
      SnackBarHelper.showErrorSnackBar('An error occurred: $e');
      rethrow;
    }
  }

  // //? Submit category (either add or update)
  submitCategory() async {
    if(categoryForUpdate != null) {
      updateCategory();

    } else {
      addCategory();
    }
  }

  // //? Delete a category
  deleteCategory(Category category) async {
    try {
      Response response = await service.deleteItem(endpointUrl: 'categories', itemId: category.sId ?? '');
      if (response.isOk) {
        ApiResponse apiResponse = ApiResponse.fromJson(response.body, null);
        if (apiResponse.success) {
          SnackBarHelper.showSuccessSnackBar(apiResponse.message);
          _dataProvider.getAllCategories();
        } else {
          SnackBarHelper.showErrorSnackBar(apiResponse.message);
        }
      }
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  //? Create form data for sending image with the body
  Future<FormData> createFormData({required XFile? imgXFile, required Map<String, dynamic> formData}) async {
    if (imgXFile != null) {
      MultipartFile multipartFile;
      if (kIsWeb) {
        String fileName = imgXFile.name;
        Uint8List byteImg = await imgXFile.readAsBytes();
        multipartFile = MultipartFile(byteImg, filename: fileName);
      } else {
        String fileName = imgXFile.path.split('/').last;
        multipartFile = MultipartFile(imgXFile.path, filename: fileName);
      }
      formData['img'] = multipartFile;
    }
    final FormData form = FormData(formData);
    return form;
  }

    //? set data for update on editing
  setDataForUpdateCategory(Category? category) {
    if (category != null) {
      clearFields();
      categoryForUpdate = category;
      categoryNameCtrl.text = category.name ?? '';
    } else {
      clearFields();
    }
  }

  //? Clear fields after adding or updating category
  clearFields() {
    categoryNameCtrl.clear();
    selectedImage = null;
    imgXFile = null;
    categoryForUpdate = null;
  }

  //? Validation method for category name
  String? validateCategoryName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Category name cannot be empty';
    }
    return null;
  }
}

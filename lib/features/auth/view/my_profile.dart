import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/profile_controller.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Personal Details'),
              Tab(text: 'Address Details'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Persistent header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(controller.nameController.text.isNotEmpty ? controller.nameController.text[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 24)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(controller.nameController.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('EMP CODE : ' + controller.empIdController.text, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab content – fills remaining space
            Expanded(child: TabBarView(children: [_buildPersonalDetailsTab(), _buildAddressTab()])),
            // Save button as a fixed footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: ElevatedButton(onPressed: () => controller.saveProfile(), child: const Text('Save & Update')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prefix (dropdown – static for now)
          _buildDropdown('Prefix', ['Mr.', 'Mrs.', 'Ms.'], 'Mr.'),
          const SizedBox(height: 12),
          // First & Last Name in a row
          Row(
            children: [
              Expanded(child: _buildTextField(controller.firstNameController, 'First Name')),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(controller.lastNameController, 'Last Name')),
            ],
          ),
          const SizedBox(height: 12),
          // Employee ID (read-only)
          _buildReadOnlyField('Employee ID', controller.empIdController.text),
          const SizedBox(height: 12),
          // Gender (radio buttons)
          _buildGenderRadio(),
          const SizedBox(height: 12),
          // Role (designation)
          _buildTextField(controller.roleController, 'Role'),
          const SizedBox(height: 12),
          // Phone Number (extra)
          _buildTextField(controller.phoneNumberController, 'Phone Number'),
          const SizedBox(height: 12),
          // Mapped Clinic/Dom (extra)
          _buildTextField(controller.clinicController, 'Mapped Clinic/Dom'),
          const SizedBox(height: 12),
          // Mapped Doctor (extra)
          _buildTextField(controller.doctorController, 'Mapped Doctor'),
          const SizedBox(height: 12),
          // Mobile Number
          _buildTextField(controller.mobileNumberController, 'Mobile Number'),
          const SizedBox(height: 12),
          // Skill Category (extra)
          _buildTextField(controller.skillCategoryController, 'Skill Category'),
          const SizedBox(height: 12),
          // Date of Birth & Age
          Row(
            children: [
              Expanded(child: _buildTextField(controller.dobController, 'Date of Birth', suffix: const Icon(Icons.calendar_today))),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Obx(() => Text(controller.age.value, style: const TextStyle(fontSize: 16))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Email Address
          _buildTextField(controller.emailController, 'Email Address'),
        ],
      ),
    );
  }

  Widget _buildAddressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Street (extra)
          _buildTextField(controller.streetController, 'Street'),
          const SizedBox(height: 12),
          // District
          _buildTextField(controller.districtController, 'District'),
          const SizedBox(height: 12),
          // City
          _buildTextField(controller.cityController, 'City'),
          const SizedBox(height: 12),
          // Pin code
          _buildTextField(controller.pinController, 'Pin code'),
          const SizedBox(height: 12),
          // Address (multiline)
          TextFormField(
            controller: controller.addressController,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Helper widgets (add these inside the ProfileScreen class)
  // ------------------------------------------------------------------

  Widget _buildTextField(TextEditingController controller, String label, {Widget? suffix}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: suffix),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
          Text(label, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String initialValue) {
    return DropdownButtonFormField<String>(
      value: initialValue,
      onChanged: (_) {},
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  Widget _buildGenderRadio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gender', style: TextStyle(fontSize: 16)),
        Row(children: [_radioButton('Male', 'Male'), _radioButton('Female', 'Female'), _radioButton('Other', 'Other')]),
      ],
    );
  }

  Widget _radioButton(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: controller.selectedGender,
          onChanged: (val) {
            controller.selectedGender = val!;
            controller.genderController.text = val;
          },
        ),
        Text(label),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:lifenity_connect/utils/ui_designs/liquid_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dummy data (you can replace with your model)
  final TextEditingController nameController = TextEditingController(text: 'Mr. Chitanya Joshi');
  final TextEditingController empIdController = TextEditingController(text: 'Emp0012456');
  final TextEditingController phoneController = TextEditingController(text: '+91 9876543210');
  final TextEditingController emailController = TextEditingController(text: 'chaitanya@example.com');
  final TextEditingController districtController = TextEditingController(text: 'Taluka');
  final TextEditingController cityController = TextEditingController(text: 'Pune');
  final TextEditingController pinController = TextEditingController(text: '411038');
  final TextEditingController addressController = TextEditingController(text: 'Flat 301, Silver Oak Apartments, Mayur Colony, Kothrud, Pune - 411038');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Personal Details'),
            Tab(text: 'Address Details'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Persistent header with name and employee ID
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(nameController.text.isNotEmpty ? nameController.text[0] : 'U', style: TextStyle(color: Colors.white, fontSize: 24)),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nameController.text, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(empIdController.text, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Personal Details
                  _buildPersonalDetailsTab(),
                  // Tab 2: Address Details
                  _buildAddressTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Save logic here
                  LiquidSnack.success('Profile updated!');
                }
              },
              child: Text('Save & Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildTextField(phoneController, 'Phone', Icons.phone),
          SizedBox(height: 16),
          _buildTextField(emailController, 'Email', Icons.email),
          SizedBox(height: 16),
          _buildTextField(districtController, 'District', Icons.location_city),
          SizedBox(height: 16),
          _buildTextField(cityController, 'City', Icons.location_on),
          SizedBox(height: 16),
          _buildTextField(pinController, 'Pin code', Icons.pin_drop),
        ],
      ),
    );
  }

  Widget _buildAddressTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextFormField(
            controller: addressController,
            maxLines: 5,
            decoration: InputDecoration(labelText: 'Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(), prefixIcon: Icon(icon)),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}

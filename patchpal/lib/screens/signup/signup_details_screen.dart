// lib/screens/signup/signup_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../widgets/patchpal_logo.dart';
import '../../widgets/login_text_field.dart';
import '../../widgets/rounded_button.dart';
import '../../services/auth_service.dart';
import '../../screens/home_screen.dart';
import 'select_account_type_screen.dart';

class SignupDetailsScreen extends StatefulWidget {
  final String email;
  final String password;
  final String fullName;
  final AccountType accountType;
  
  const SignupDetailsScreen({
    Key? key, 
    required this.email,
    required this.password,
    required this.fullName,
    required this.accountType,
  }) : super(key: key);

  @override
  State<SignupDetailsScreen> createState() => _SignupDetailsScreenState();
}

class _SignupDetailsScreenState extends State<SignupDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  
  // Fields for additional information based on account type
  final _licenseNumberController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _hospitalController = TextEditingController();
  
  // Fields for personal account
  String? _selectedGender;
  final _ageController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _specialtyController.dispose();
    _hospitalController.dispose();
    _ageController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Prepare additional info based on account type
      Map<String, dynamic> additionalInfo = {};
      
      if (widget.accountType == AccountType.personal) {
        additionalInfo = {
          'gender': _selectedGender,
          'age': _ageController.text,
          'emergencyContact': _emergencyContactController.text,
        };
      } else {
        additionalInfo = {
          'licenseNumber': _licenseNumberController.text,
          'specialty': _specialtyController.text,
          'hospital': _hospitalController.text,
        };
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        email: widget.email,
        password: widget.password,
        fullName: widget.fullName,
        accountType: widget.accountType == AccountType.personal ? 'personal' : 'healthcare_professional',
        additionalInfo: additionalInfo,
      );

      if (success) {
        _showSuccessSnackBar('Account created successfully!');
        
        // Navigate to the home screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage;
        });
        
        if (_errorMessage != null) {
          _showErrorSnackBar(_errorMessage!);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _showErrorSnackBar(_errorMessage!);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back Button and Logo
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const PatchPalLogo(size: 40),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              
              // Title
              const Text(
                'Create an Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Progress Indicator
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Form
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Account Type Specific Fields
                          if (widget.accountType == AccountType.healthcareProfessional) ...[
                            _buildHealthcareProfessionalFields(),
                          ] else ...[
                            _buildPersonalAccountFields(),
                          ],
                          
                          const SizedBox(height: 30),
                          
                          // Error message
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          
                          // Submit Button
                          _isLoading
                              ? const Center(child: CircularProgressIndicator(color: Colors.white))
                              : Center(
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.arrow_forward,
                                        color: Color(0xFF1E88C9),
                                        size: 30,
                                      ),
                                      onPressed: _handleSignup,
                                    ),
                                  ),
                                ),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
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

  Widget _buildHealthcareProfessionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Professional Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        // License Number
        const Text(
          'License Number',
          style: AppTextStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        LoginTextField(
          controller: _licenseNumberController,
          hintText: 'Enter your license number',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your license number';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        // Specialty
        const Text(
          'Specialty',
          style: AppTextStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        LoginTextField(
          controller: _specialtyController,
          hintText: 'Your medical specialty',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your specialty';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        // Hospital/Clinic
        const Text(
          'Hospital/Clinic',
          style: AppTextStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        LoginTextField(
          controller: _hospitalController,
          hintText: 'Where you practice',
        ),
      ],
    );
  }

  Widget _buildPersonalAccountFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Personal Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        // Gender
        const Text(
          'Gender',
          style: AppTextStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Select your gender'),
              value: _selectedGender,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 24,
              elevation: 16,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
              },
              items: <String>['Male', 'Female', 'Other', 'Prefer not to say']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Age
        const Text(
          'Age',
          style: AppTextStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        LoginTextField(
          controller: _ageController,
          hintText: 'Your age',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        // Emergency Contact
        const Text(
          'Emergency Contact',
          style: AppTextStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        LoginTextField(
          controller: _emergencyContactController,
          hintText: 'Emergency contact number',
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}
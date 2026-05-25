import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../utils/constants.dart';
import 'qr_scanner_screen.dart';

class BackendConfigScreen extends StatefulWidget {
  final bool isEditing;

  const BackendConfigScreen({super.key, this.isEditing = false});

  @override
  State<BackendConfigScreen> createState() => _BackendConfigScreenState();
}

class _BackendConfigScreenState extends State<BackendConfigScreen> {
  final TextEditingController _domainController = TextEditingController();
  bool _isLoading = false;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentDomain();
  }

  Future<void> _loadCurrentDomain() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final savedDomain = prefs.getString('backend_domain') ?? '';
    _domainController.text = savedDomain;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final input = _domainController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _testResult = 'Please enter a domain or IP address.';
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    // Format the URL for testing
    String testUrl = input;
    if (!testUrl.startsWith('http://') && !testUrl.startsWith('https://')) {
      testUrl = 'http://$testUrl';
    }
    if (testUrl.endsWith('/')) {
      testUrl = testUrl.substring(0, testUrl.length - 1);
    }

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      
      // Test the endpoint (health check or menu endpoint)
      final response = await dio.get('$testUrl/api/menu');
      
      if (response.statusCode == 200) {
        setState(() {
          _testSuccess = true;
          _testResult = 'Connection successful! Host is reachable.';
        });
      } else {
        setState(() {
          _testSuccess = true; // Still reachable
          _testResult = 'Reachable, but returned status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _testSuccess = false;
        if (e is DioException) {
          if (e.type == DioExceptionType.connectionTimeout) {
            _testResult = 'Connection timed out. Check if the server is running and accessible.';
          } else {
            _testResult = 'Failed to connect: ${e.message}';
          }
        } else {
          _testResult = 'Error connecting: $e';
        }
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _saveAndProceed() async {
    final input = _domainController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid backend domain.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_domain', input);
    
    // Apply changes to Constants
    Constants.setBaseUrl(input);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (widget.isEditing) {
      // Just go back to the previous screen if we came from settings
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backend domain updated to: $input'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Navigate to QrScannerScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const QrScannerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13), // Premium Dark
      appBar: AppBar(
        title: Text(
          'SERVER CONFIG',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.amber[700],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: widget.isEditing
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.dns_outlined,
                    size: 80,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Setup Backend Connection',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter your Railway deployment domain or local server IP to connect the app to the restaurant API.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Text Field
                  TextField(
                    controller: _domainController,
                    keyboardType: TextInputType.url,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Backend Domain / IP Address',
                      labelStyle: GoogleFonts.outfit(color: Colors.amber[700]),
                      hintText: 'e.g., your-app.up.railway.app or 192.168.1.72:8080',
                      hintStyle: GoogleFonts.outfit(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.03),
                      prefixIcon: const Icon(Icons.link, color: Colors.amber),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.amber[700]!, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Connection Test Status
                  if (_testResult != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _testSuccess
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _testSuccess
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _testSuccess ? Icons.check_circle : Icons.error,
                            color: _testSuccess ? Colors.green : Colors.redAccent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _testResult!,
                              style: GoogleFonts.outfit(
                                color: _testSuccess ? Colors.green[200] : Colors.red[200],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Test Connection Button
                  OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.amber,
                            ),
                          )
                        : const Icon(Icons.network_check),
                    label: Text(
                      _isTesting ? 'Testing...' : 'Test Connection',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber,
                      side: BorderSide(color: Colors.amber.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Save & Connect Button
                  ElevatedButton(
                    onPressed: _saveAndProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      widget.isEditing ? 'Save Changes' : 'Connect & Proceed',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

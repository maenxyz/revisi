import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final user = await AuthService.instance.login(_u.text.trim(), _p.text);
      if (!mounted) return;
      setState(() => _loading = false);

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username / password salah')),
        );
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/search', (_) => false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal: $e')),
      );
    }
  }

  Widget _label(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16, // agak gede
        fontWeight: FontWeight.w700, // bold
      ),
    ),
  );

  InputDecoration _dec({String? hint}) => InputDecoration(
    hintText: hint,
    // bikin field lebih tinggi
    isDense: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 30),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420), // form gak kepanjangan
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label('Username'),
                const SizedBox(height: 6),
                TextField(
                  controller: _u,
                  decoration: _dec(hint: 'Masukkan username'),
                ),
                const SizedBox(height: 24),
                _label('Password'),
                const SizedBox(height: 6),
                TextField(
                  controller: _p,
                  decoration: _dec(hint: 'Masukkan password'),
                  obscureText: true,
                ),
                const SizedBox(height: 28),

                // Tombol hijau, dipendekin & center
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Login'),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Register dengan underline
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/register'),
                    child: const Text(
                      'Register',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

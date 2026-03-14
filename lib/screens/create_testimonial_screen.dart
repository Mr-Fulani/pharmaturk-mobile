import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/testimonial_service.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';

/// Экран создания отзыва. Доступен только верифицированным пользователям.
class CreateTestimonialScreen extends StatefulWidget {
  const CreateTestimonialScreen({super.key});

  @override
  State<CreateTestimonialScreen> createState() => _CreateTestimonialScreenState();
}

class _CreateTestimonialScreenState extends State<CreateTestimonialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _error = null;
    if (!_formKey.currentState!.validate()) return;

    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _error = context.tr('enter_review_text'));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await TestimonialService().createTestimonial(
        TestimonialCreate(content: content, rating: _rating),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('review_submitted')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('leave_review')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('leave_review_hint'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('rating'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = star),
                    icon: Icon(
                      star <= _rating ? Icons.star : Icons.star_border,
                      size: 40,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _contentController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: context.tr('review_text'),
                  hintText: context.tr('review_text_hint'),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return context.tr('enter_review_text');
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red[700], fontSize: 14),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(context.tr('submit_review')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

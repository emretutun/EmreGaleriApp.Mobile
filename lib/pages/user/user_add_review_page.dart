// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:emregalerimobile/models/order.dart';
import 'package:emregalerimobile/services/review_service.dart';

class AddReviewPage extends StatefulWidget {
  final Order order;
  const AddReviewPage({required this.order, super.key});

  @override
  State<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage> {
  final _formKey = GlobalKey<FormState>();
  int _rating = 5;
  String _comment = '';
  bool _isLoading = false;

  void _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      // Basitlik için ilk araç seçiliyor, istersen burayı geliştirebiliriz
      await ReviewService().addReview(
        orderId: widget.order.id,
        carId: widget.order.items.first.carId,
        rating: _rating,
        comment: _comment,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorumunuz kaydedildi.')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yorum eklenirken hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1;
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yorum Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "Sipariş No: ${widget.order.id}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              buildRatingStars(),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Yorumunuz',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Yorum boş olamaz';
                  }
                  return null;
                },
                onSaved: (value) {
                  _comment = value!.trim();
                },
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitReview,
                      child: const Text('Gönder'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

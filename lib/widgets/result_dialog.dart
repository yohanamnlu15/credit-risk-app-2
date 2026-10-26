import 'package:flutter/material.dart';
import '../models/prediction_result.dart';

class ResultDialog extends StatelessWidget {
  final PredictionResult result;

  const ResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final bool isLancar = result.isLancar;
    final Color mainColor = isLancar ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final Color bgColor = isLancar ? const Color(0xFFE6F4EA) : const Color(0xFFFDECEA);
    final IconData icon = isLancar ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          final safeOpacity = value.clamp(0.0, 1.0);
          return Opacity(opacity: safeOpacity, child: Transform.scale(scale: value, child: child));
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: mainColor, size: 46),
              ),
              const SizedBox(height: 20),
              Text('Hasil Prediksi Risiko', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(result.status, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: mainColor)),
              const SizedBox(height: 4),
              Text(result.debiturName, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tingkat Kepercayaan Tiap Kelas',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 10),
              ...result.probabilities.entries.map((e) {
                final barColor = e.key == 'Lancar' ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1B2A41))),
                          Text('${e.value.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: barColor)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (e.value / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE4E8EE),
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Ringkasan Faktor Penilaian', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              ),
              const SizedBox(height: 8),
              ...result.summaryFactors.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12.5, color: Color(0xFF5B6B79)))),
                      Text(e.value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1B2A41))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
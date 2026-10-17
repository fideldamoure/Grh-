import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart' show PdfColor, PdfColors, PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(const InspectionApp());
}

class InspectionApp extends StatelessWidget {
  const InspectionApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مراقبة انتقاء الأعوان المتعاقدين',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _municipalityController = TextEditingController();

  final List<Map<String, dynamic>> _procedures = [
    {
      "id": "1",
      "title": "الترخيص المالي والمخطط",
      "desc": "وجود مناصب مالية شاغرة ومصادق عليها ضمن مخطط تسيير الموارد البشرية (PGRH)",
      "status": false,
      "notes": ""
    },
    {
      "id": "2",
      "title": "القرار أو الإعلان الإداري",
      "desc": "صدور قرار/أمر فتح مسابقة التوظيف محدد فيه عدد المناصب والشروط",
      "status": false,
      "notes": ""
    },
    {
      "id": "3",
      "title": "الإشهار والعلانية",
      "desc": "تعليق الإعلان في المقرات والإشهار لمدة 15 يوم عمل على الأقل",
      "status": false,
      "notes": ""
    },
    {
      "id": "4",
      "title": "تشكيل لجنة الانتقاء",
      "desc": "تعيين لجنة الانتقاء والتدقيق بموجب قرار رسمي",
      "status": false,
      "notes": ""
    },
    {
      "id": "5",
      "title": "سجل إيداع الملفات",
      "desc": "فتح سجل قيد خاص بتسليم وصل استلام الملفات مؤرخ ومؤشر عليه",
      "status": false,
      "notes": ""
    },
    {
      "id": "6",
      "title": "دراسة الطعون",
      "desc": "اجتماع لجنة الطعون لبحث التظلمات قبل الإعلان النهائي",
      "status": false,
      "notes": ""
    },
    {
      "id": "7",
      "title": "إجراء المقابلة والتنقيط",
      "desc": "التزام اللجنة بشبكة التنقيط القانونية وتدوين المحضر",
      "status": false,
      "notes": ""
    },
    {
      "id": "8",
      "title": "المصادقة الإدارية",
      "desc": "إرسال المحضر النهائي لمفتشية الوظيفة العمومية للمصادقة",
      "status": false,
      "notes": ""
    },
  ];

  final List<Map<String, dynamic>> _candidateFiles = [
    {"id": "1", "title": "طلب خطي للترشح", "deposit": false, "appointment": false},
    {"id": "2", "title": "بطاقة الهوية الوطنية", "deposit": false, "appointment": false},
    {"id": "3", "title": "المؤهل / الشهادة العلمية", "deposit": false, "appointment": false},
    {"id": "4", "title": "استمارة معلومات", "deposit": false, "appointment": false},
    {"id": "5", "title": "إثبات الخدمة الوطنية", "deposit": false, "appointment": false},
    {"id": "6", "title": "شهادات الخبرة المهنية", "deposit": false, "appointment": false},
    {"id": "7", "title": "شهادة الإقامة", "deposit": false, "appointment": false},
    {"id": "8", "title": "السوابق العدلية (صحيفة 03)", "deposit": false, "appointment": false},
    {"id": "9", "title": "الشهادات الطبية", "deposit": false, "appointment": false},
    {"id": "10", "title": "صور شخصية", "deposit": false, "appointment": false},
  ];

  @override
  void dispose() {
    _municipalityController.dispose();
    super.dispose();
  }

  void _openReportPreview() {
    final String municipalityName = _municipalityController.text.trim();
    if (municipalityName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد واسم البلدية قبل معاينة التقرير!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPreviewScreen(
          municipalityName: municipalityName,
          procedures: _procedures,
          candidateFiles: _candidateFiles,
        ),
      ),
    );
  }

  // يُغيَّر عند تحميل سجل محفوظ لإعادة بناء حقول الملاحظات.
  int _version = 0;

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _saveData() async {
    final String name = _municipalityController.text.trim();
    if (name.isEmpty) {
      _toast('يرجى كتابة اسم البلدية أولاً!', Colors.red);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final record = {
      'procedures': _procedures
          .map((p) => {'status': p['status'], 'notes': p['notes']})
          .toList(),
      'files': _candidateFiles
          .map((f) => {'deposit': f['deposit'], 'appointment': f['appointment']})
          .toList(),
    };
    await prefs.setString('rec_$name', jsonEncode(record));
    final names = prefs.getStringList('municipalities') ?? <String>[];
    if (!names.contains(name)) {
      names.add(name);
      await prefs.setStringList('municipalities', names);
    }
    if (!mounted) return;
    _toast('تم حفظ بيانات بلدية: $name بنجاح!', Colors.green);
  }

  Future<void> _loadRecord(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('rec_$name');
    if (raw == null) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final procs = data['procedures'] as List<dynamic>;
    final files = data['files'] as List<dynamic>;
    setState(() {
      for (int i = 0; i < _procedures.length && i < procs.length; i++) {
        _procedures[i]['status'] = procs[i]['status'] == true;
        _procedures[i]['notes'] = (procs[i]['notes'] ?? '') as String;
      }
      for (int i = 0; i < _candidateFiles.length && i < files.length; i++) {
        _candidateFiles[i]['deposit'] = files[i]['deposit'] == true;
        _candidateFiles[i]['appointment'] = files[i]['appointment'] == true;
      }
      _municipalityController.text = name;
      _version++;
    });
  }

  Future<void> _deleteRecord(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rec_$name');
    final names = prefs.getStringList('municipalities') ?? <String>[];
    names.remove(name);
    await prefs.setStringList('municipalities', names);
  }

  Future<void> _openSavedList() async {
    final prefs = await SharedPreferences.getInstance();
    final names = List<String>.from(prefs.getStringList('municipalities') ?? <String>[]);
    if (!mounted) return;
    if (names.isEmpty) {
      _toast('لا توجد تقارير محفوظة بعد.', Colors.orange.shade800);
      return;
    }
    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setDialog) => AlertDialog(
            title: const Text('التقارير المحفوظة'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: names
                    .map((n) => ListTile(
                          title: Text(n),
                          onTap: () {
                            Navigator.pop(ctx);
                            _loadRecord(n);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _deleteRecord(n);
                              setDialog(() => names.remove(n));
                              if (names.isEmpty && ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مراقبة انتقاء الأعوان المتعاقدين'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _openSavedList,
              tooltip: 'فتح تقرير محفوظ',
            ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _openReportPreview,
              tooltip: 'معاينة التقرير والطباعة',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveData,
              tooltip: 'حفظ التقرير',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                color: Colors.indigo.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_city,
                          color: Colors.indigo, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _municipalityController,
                          decoration: const InputDecoration(
                            labelText: 'اسم البلدية المعنية',
                            hintText: 'أدخل اسم البلدية (مثال: بلدية سبدو)',
                            border: OutlineInputBorder(),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'أولاً: مراقبة الإجراءات الإدارية والتنظيمية',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _procedures.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _procedures[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${item["id"]}. ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  item["title"],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ),
                              const Text('مطابق:',
                                  style: TextStyle(fontSize: 12)),
                              Checkbox(
                                value: item["status"],
                                onChanged: (bool? val) {
                                  setState(() {
                                    item["status"] = val ?? false;
                                  });
                                },
                              ),
                            ],
                          ),
                          Text(item["desc"],
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700)),
                          const SizedBox(height: 4),
                          TextFormField(
                            key: ValueKey('note_${item["id"]}_$_version'),
                            initialValue: item["notes"],
                            onChanged: (val) => item["notes"] = val,
                            decoration: const InputDecoration(
                              hintText: 'ملاحظات / توصيات (اختياري)',
                              isDense: true,
                              contentPadding: EdgeInsets.all(8),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ثانياً: مراقبة واستيفاء الملف النظامي للمترشح',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1.5),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.indigo.shade100),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('الوثيقة',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('عند الإيداع',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11),
                              textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('عند التعيين',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11),
                              textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                    ..._candidateFiles.map((file) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(file["title"],
                                style: const TextStyle(fontSize: 12)),
                          ),
                          Center(
                            child: Checkbox(
                              value: file["deposit"],
                              onChanged: (bool? val) {
                                setState(() {
                                  file["deposit"] = val ?? false;
                                });
                              },
                            ),
                          ),
                          Center(
                            child: Checkbox(
                              value: file["appointment"],
                              onChanged: (bool? val) {
                                setState(() {
                                  file["appointment"] = val ?? false;
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openReportPreview,
                      icon: const Icon(Icons.print),
                      label: const Text('معاينة وطباعة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveData,
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ البيانات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportPreviewScreen extends StatelessWidget {
  final String municipalityName;
  final List<Map<String, dynamic>> procedures;
  final List<Map<String, dynamic>> candidateFiles;

  const ReportPreviewScreen({
    Key? key,
    required this.municipalityName,
    required this.procedures,
    required this.candidateFiles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('معاينة التقرير النهائي')),
        body: PdfPreview(
          build: (format) => buildReportPdf(
            municipalityName: municipalityName,
            procedures: procedures,
            candidateFiles: candidateFiles,
            format: format,
          ),
          pdfFileName: 'تقرير_$municipalityName.pdf',
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          allowSharing: true,
          allowPrinting: true,
        ),
      ),
    );
  }
}

// ====================== توليد ملف PDF ======================
Future<Uint8List> buildReportPdf({
  required String municipalityName,
  required List<Map<String, dynamic>> procedures,
  required List<Map<String, dynamic>> candidateFiles,
  PdfPageFormat format = PdfPageFormat.a4,
}) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'));

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  const rtl = pw.TextDirection.rtl;

  pw.Widget txt(String s,
      {double size = 10,
      bool isBold = false,
      pw.TextAlign align = pw.TextAlign.right,
      PdfColor? color}) {
    return pw.Text(
      s,
      textDirection: rtl,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: size,
        fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      ),
    );
  }

  pw.Widget cell(pw.Widget child, {PdfColor? bg}) => pw.Container(
        color: bg,
        padding: const pw.EdgeInsets.all(5),
        alignment: pw.Alignment.center,
        child: child,
      );

  final valid = procedures.where((e) => e["status"] == true).length;
  final headerBg = PdfColors.grey300;

  // الجداول تُرسم من اليسار إلى اليمين، لذلك نعكس ترتيب الأعمدة ليظهر العمود الأول على اليمين.
  final proceduresTable = pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.6),
    columnWidths: {
      0: const pw.FlexColumnWidth(3),
      1: const pw.FlexColumnWidth(1.4),
      2: const pw.FlexColumnWidth(3),
    },
    children: [
      pw.TableRow(children: [
        cell(txt('الملاحظات', isBold: true, align: pw.TextAlign.center), bg: headerBg),
        cell(txt('الحالة', isBold: true, align: pw.TextAlign.center), bg: headerBg),
        cell(txt('الإجراء', isBold: true, align: pw.TextAlign.center), bg: headerBg),
      ]),
      ...procedures.map((p) {
        final ok = p["status"] == true;
        final notes = (p["notes"] as String).trim();
        return pw.TableRow(children: [
          cell(txt(notes.isEmpty ? '-' : notes, size: 9)),
          cell(txt(ok ? 'مطابق' : 'غير مطابق',
              size: 9,
              isBold: true,
              align: pw.TextAlign.center,
              color: ok ? PdfColors.green800 : PdfColors.red800)),
          cell(txt('${p["id"]}. ${p["title"]}', size: 9)),
        ]);
      }),
    ],
  );

  final filesTable = pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.6),
    columnWidths: {
      0: const pw.FlexColumnWidth(1.5),
      1: const pw.FlexColumnWidth(1.5),
      2: const pw.FlexColumnWidth(3.5),
    },
    children: [
      pw.TableRow(children: [
        cell(txt('عند التعيين', isBold: true, align: pw.TextAlign.center), bg: headerBg),
        cell(txt('عند الإيداع', isBold: true, align: pw.TextAlign.center), bg: headerBg),
        cell(txt('الوثيقة', isBold: true, align: pw.TextAlign.center), bg: headerBg),
      ]),
      ...candidateFiles.map((f) {
        String mark(bool v) => v ? 'نعم' : 'لا';
        return pw.TableRow(children: [
          cell(txt(mark(f["appointment"] == true), size: 9, align: pw.TextAlign.center)),
          cell(txt(mark(f["deposit"] == true), size: 9, align: pw.TextAlign.center)),
          cell(txt('${f["id"]}. ${f["title"]}', size: 9)),
        ]);
      }),
    ],
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(28),
      textDirection: rtl,
      build: (context) => [
        pw.Center(
          child: txt(
            'الجمهورية الجزائرية الديمقراطية الشعبية\nوزارة الداخلية والجماعات المحلية والتهيئة العمرانية',
            size: 11,
            isBold: true,
            align: pw.TextAlign.center,
          ),
        ),
        pw.Divider(thickness: 1.2),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.indigo),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(children: [
            txt('تقرير مراقبة عملية انتقاء الأعوان المتعاقدين',
                size: 14, isBold: true, align: pw.TextAlign.center),
            pw.SizedBox(height: 4),
            txt('البلدية المعنية: $municipalityName',
                size: 12, isBold: true, align: pw.TextAlign.center),
          ]),
        ),
        pw.SizedBox(height: 10),
        txt('الإجراءات المطابقة: $valid / ${procedures.length}',
            size: 11, isBold: true),
        pw.SizedBox(height: 10),
        txt('أولاً: مدى التقيد بالإجراءات الإدارية والتنظيمية',
            size: 12, isBold: true),
        pw.SizedBox(height: 4),
        proceduresTable,
        pw.SizedBox(height: 14),
        txt('ثانياً: مراقبة واستيفاء الملف النظامي للمترشح',
            size: 12, isBold: true),
        pw.SizedBox(height: 4),
        filesTable,
        pw.SizedBox(height: 28),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // في الصفحة العربية: رئيس اللجنة على اليمين، المفتش على اليسار.
            txt('مفتش الوظيفة العمومية\n(التوقيع والختم)',
                size: 10, isBold: true, align: pw.TextAlign.center),
            txt('رئيس لجنة الانتقاء\n(التوقيع والختم)',
                size: 10, isBold: true, align: pw.TextAlign.center),
          ],
        ),
      ],
    ),
  );

  return doc.save();
}

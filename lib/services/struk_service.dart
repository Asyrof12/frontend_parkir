import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

/// Service untuk generate dan print struk parkir
class StrukService {
  /// Generate PDF struk kendaraan masuk
  static Future<pw.Document> generateStrukMasuk({
    required int idParkir,
    required String platNomor,
    required String jenisKendaraan,
    required String namaArea,
    required String tarifPerJam,
    required DateTime waktuMasuk,
    required String namaPetugas,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'SISTEM PARKIR',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'STRUK MASUK',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              
              // Info Transaksi
              _buildRow('ID Parkir', '#$idParkir'),
              _buildRow('Plat Nomor', platNomor),
              _buildRow('Jenis', jenisKendaraan),
              _buildRow('Area', namaArea),
              _buildRow('Tarif', tarifPerJam),
              pw.Divider(),
              
              // Waktu
              _buildRow('Waktu Masuk', DateFormat('dd MMM yyyy').format(waktuMasuk)),
              _buildRow('Jam', DateFormat('HH:mm:ss').format(waktuMasuk)),
              pw.Divider(),
              
              // Petugas
              _buildRow('Petugas', namaPetugas),
              pw.SizedBox(height: 12),
              
              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Simpan struk ini sebagai bukti',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Terima Kasih',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Generate PDF struk kendaraan keluar
  static Future<pw.Document> generateStrukKeluar({
    required int idParkir,
    required String platNomor,
    required String jenisKendaraan,
    required String namaArea,
    required String tarifAwal,
    required String tarifNambah,
    required DateTime waktuMasuk,
    required DateTime waktuKeluar,
    required int durasiJam,
    required int biayaTotal,
    required String namaPetugas,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          int jamTambahan = durasiJam - 1;
          if (jamTambahan < 0) jamTambahan = 0;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'SISTEM PARKIR',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'STRUK PEMBAYARAN',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              
              // Info Transaksi
              _buildRow('ID Parkir', '#$idParkir'),
              _buildRow('Plat Nomor', platNomor),
              _buildRow('Jenis', jenisKendaraan),
              _buildRow('Area', namaArea),
              pw.Divider(),
              
              // Waktu
              _buildRow('Masuk', DateFormat('dd/MM HH:mm').format(waktuMasuk)),
              _buildRow('Keluar', DateFormat('dd/MM HH:mm').format(waktuKeluar)),
              _buildRow('Durasi', '$durasiJam jam'),
              pw.Divider(),
              
              // Biaya
              _buildRow('Tarif Awal', tarifAwal),
              if (jamTambahan > 0) 
                _buildRow('Nambah ($jamTambahan jam)', tarifNambah),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 2),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL BAYAR',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp',
                        decimalDigits: 0,
                      ).format(biayaTotal),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              
              // Petugas
              _buildRow('Petugas', namaPetugas),
              _buildRow('Waktu Cetak', DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())),
              pw.SizedBox(height: 12),
              
              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Terima kasih atas kunjungan Anda',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Hati-hati di jalan',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Helper untuk membuat row info
  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 11)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Print atau preview struk
  static Future<void> printStruk(pw.Document pdf, String title) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: title,
    );
  }

  /// Share struk sebagai PDF file
  static Future<void> shareStruk(pw.Document pdf, String filename) async {
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: filename,
    );
  }
}

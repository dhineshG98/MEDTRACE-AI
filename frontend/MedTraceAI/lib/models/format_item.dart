import 'package:flutter/material.dart';

class FormatItem {
  final String name;
  final String label;
  final IconData icon;
  final Color accentColor;
  final String category;

  const FormatItem({
    required this.name,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.category,
  });

  static const List<FormatItem> supportedFormats = [
    // Documents
    FormatItem(
      name: 'PDF',
      label: 'Adobe Acrobat',
      icon: Icons.picture_as_pdf_rounded,
      accentColor: Color(0xFFF43F5E),
      category: 'Document',
    ),
    FormatItem(
      name: 'DOC',
      label: 'MS Word Legacy',
      icon: Icons.description_rounded,
      accentColor: Color(0xFF3B82F6),
      category: 'Document',
    ),
    FormatItem(
      name: 'DOCX',
      label: 'MS Word Document',
      icon: Icons.article_rounded,
      accentColor: Color(0xFF2563EB),
      category: 'Document',
    ),
    FormatItem(
      name: 'TXT',
      label: 'Plain Text File',
      icon: Icons.text_snippet_rounded,
      accentColor: Color(0xFF94A3B8),
      category: 'Document',
    ),

    // Spreadsheets & Tabular Data
    FormatItem(
      name: 'CSV',
      label: 'Comma Separated',
      icon: Icons.table_chart_rounded,
      accentColor: Color(0xFF10B981),
      category: 'Data',
    ),
    FormatItem(
      name: 'XLS',
      label: 'MS Excel Legacy',
      icon: Icons.grid_on_rounded,
      accentColor: Color(0xFF059669),
      category: 'Data',
    ),
    FormatItem(
      name: 'XLSX',
      label: 'MS Excel Sheet',
      icon: Icons.table_view_rounded,
      accentColor: Color(0xFF047857),
      category: 'Data',
    ),

    // Presentations
    FormatItem(
      name: 'PPT',
      label: 'PowerPoint Legacy',
      icon: Icons.slideshow_rounded,
      accentColor: Color(0xFFF97316),
      category: 'Presentation',
    ),
    FormatItem(
      name: 'PPTX',
      label: 'PowerPoint Slide',
      icon: Icons.co_present_rounded,
      accentColor: Color(0xFFEA580C),
      category: 'Presentation',
    ),

    // Images & Diagnostic Scans
    FormatItem(
      name: 'PNG',
      label: 'Lossless Bitmap',
      icon: Icons.image_rounded,
      accentColor: Color(0xFF8B5CF6),
      category: 'Image',
    ),
    FormatItem(
      name: 'JPG',
      label: 'Compressed Image',
      icon: Icons.photo_rounded,
      accentColor: Color(0xFFA855F7),
      category: 'Image',
    ),
    FormatItem(
      name: 'JPEG',
      label: 'Digital Diagnostic',
      icon: Icons.crop_original_rounded,
      accentColor: Color(0xFFC084FC),
      category: 'Image',
    ),
  ];
}

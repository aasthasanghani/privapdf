import 'package:flutter/material.dart';

/// The categories shown on the dashboard, in display order.
enum ToolCategory { organize, convert, enhance }

extension ToolCategoryLabel on ToolCategory {
  String get label => switch (this) {
        ToolCategory.organize => 'Organize',
        ToolCategory.convert => 'Convert',
        ToolCategory.enhance => 'Enhance',
      };
}

/// One tool tile on the dashboard. [ready] flips to true as each feature
/// is implemented; until then the tile opens a short "in progress" screen.
class ToolDef {
  const ToolDef({
    required this.id,
    required this.label,
    required this.icon,
    required this.category,
    this.ready = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final ToolCategory category;
  final bool ready;
}

const List<ToolDef> kTools = [
  // Organize
  ToolDef(id: 'merge', label: 'Merge PDFs', icon: Icons.merge_outlined, category: ToolCategory.organize),
  ToolDef(id: 'split', label: 'Split & Extract', icon: Icons.content_cut_outlined, category: ToolCategory.organize),
  ToolDef(id: 'reorder', label: 'Reorder & Rotate', icon: Icons.swap_vert_outlined, category: ToolCategory.organize),
  // Convert
  ToolDef(id: 'img2pdf', label: 'Images to PDF', icon: Icons.image_outlined, category: ToolCategory.convert),
  ToolDef(id: 'pdf2img', label: 'PDF to Images', icon: Icons.photo_library_outlined, category: ToolCategory.convert),
  // Enhance
  ToolDef(id: 'watermark', label: 'Add Watermark', icon: Icons.branding_watermark_outlined, category: ToolCategory.enhance),
  ToolDef(id: 'pagenum', label: 'Add Page Numbers', icon: Icons.format_list_numbered_outlined, category: ToolCategory.enhance),
  ToolDef(id: 'ocr', label: 'Text OCR', icon: Icons.text_fields_outlined, category: ToolCategory.enhance),
  ToolDef(id: 'searchable', label: 'Searchable PDF', icon: Icons.manage_search_outlined, category: ToolCategory.enhance),
];

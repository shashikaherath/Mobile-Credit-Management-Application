import os

def process_file(filepath):
    if "admin" in filepath:
        return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # If already processed
    if "google_fonts.dart" in content and "GoogleFonts.poppins" in content:
        # proceed anyway since we might need border radius adjustments
        pass
    
    original_content = content

    # 1. Add google_fonts import if not present
    if "import 'package:flutter/material.dart';" in content and "google_fonts.dart" not in content:
        content = content.replace(
            "import 'package:flutter/material.dart';",
            "import 'package:flutter/material.dart';\nimport 'package:google_fonts/google_fonts.dart';"
        )

    # 2. Modernize Border Radii
    content = content.replace("BorderRadius.circular(8)", "BorderRadius.circular(12)")
    content = content.replace("BorderRadius.circular(10)", "BorderRadius.circular(16)")
    content = content.replace("BorderRadius.circular(14)", "BorderRadius.circular(20)")

    # 3. Modernize box shadows (soft shadows)
    content = content.replace("Colors.black.withValues(alpha: 0.04), blurRadius: 8", "AppColors.textDark.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)")
    content = content.replace("Colors.black.withValues(alpha: 0.04)", "AppColors.textDark.withValues(alpha: 0.04)")
    content = content.replace("Colors.black.withValues(alpha: 0.05)", "AppColors.textDark.withValues(alpha: 0.05)")

    # 4. Replace TextStyle with GoogleFonts
    content = content.replace("const TextStyle(", "GoogleFonts.poppins(")
    content = content.replace("const TextStyle", "GoogleFonts.poppins")
    content = content.replace("TextStyle(", "GoogleFonts.poppins(")

    # 5. Remove `const ` keyword from standard Widget instantiations since GoogleFonts.poppins lacks const
    widgets = [
        "Text", "TextSpan", "RichText", "Padding", "Center", "Column", "Row", 
        "Container", "Icon", "Expanded", "SizedBox", "Align", "DecoratedBox", 
        "ListTile", "Card", "Row", "Stack"
    ]
    for w in widgets:
       content = content.replace(f"const {w}(", f"{w}(")
       
    # There could also be `const []` arrays holding Text widgets
    content = content.replace("const [", "[")

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk("lib/features"):
    for file in files:
        if file.endswith(".dart"):
            process_file(os.path.join(root, file))

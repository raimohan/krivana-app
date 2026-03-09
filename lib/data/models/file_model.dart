class FileItem {
  const FileItem({
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.children = const [],
    this.size,
    this.lastModified,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final List<FileItem> children;
  final int? size;
  final DateTime? lastModified;

  String get extension {
    if (isDirectory) return '';
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1);
  }

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'] as String,
      path: json['path'] as String,
      isDirectory: json['is_directory'] as bool? ?? false,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => FileItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      size: json['size'] as int?,
      lastModified: json['last_modified'] != null
          ? DateTime.parse(json['last_modified'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'is_directory': isDirectory,
        'children': children.map((e) => e.toJson()).toList(),
        'size': size,
        'last_modified': lastModified?.toIso8601String(),
      };
}

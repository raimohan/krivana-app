class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.name,
    this.description,
    this.techStack,
    this.isGitHubImported = false,
    this.gitHubRepoUrl,
    this.isPinned = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? techStack;
  final bool isGitHubImported;
  final String? gitHubRepoUrl;
  final bool isPinned;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProjectModel copyWith({
    String? name,
    String? description,
    String? techStack,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      techStack: techStack ?? this.techStack,
      isGitHubImported: isGitHubImported,
      gitHubRepoUrl: gitHubRepoUrl,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      techStack: json['tech_stack'] as String?,
      isGitHubImported: json['is_github_imported'] as bool? ?? false,
      gitHubRepoUrl: json['github_repo_url'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'tech_stack': techStack,
        'is_github_imported': isGitHubImported,
        'github_repo_url': gitHubRepoUrl,
        'is_pinned': isPinned,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}

abstract class SvgPaths {
  // Logos
  static const krivanaLogo = 'assets/svgs/logos/krivana_logo.svg';
  static const krivanaIcon = 'assets/svgs/logos/krivana_icon.svg';
  static const krivanaWordmark = 'assets/svgs/logos/krivana_wordmark.svg';

  // Navigation
  static const icDashboard = 'assets/svgs/icons/nav/ic_dashboard.svg';
  static const icProjects = 'assets/svgs/icons/nav/ic_projects.svg';
  static const icNotifications = 'assets/svgs/icons/nav/ic_notifications.svg';
  static const icSettings = 'assets/svgs/icons/nav/ic_settings.svg';

  // Actions
  static const icPlus = 'assets/svgs/icons/actions/ic_plus.svg';
  static const icBack = 'assets/svgs/icons/actions/ic_back.svg';
  static const icClose = 'assets/svgs/icons/actions/ic_close.svg';
  static const icSearch = 'assets/svgs/icons/actions/ic_search.svg';
  static const icMenuHamburger =
      'assets/svgs/icons/actions/ic_menu_hamburger.svg';
  static const icThreeDots = 'assets/svgs/icons/actions/ic_three_dots.svg';
  static const icCopy = 'assets/svgs/icons/actions/ic_copy.svg';
  static const icTrash = 'assets/svgs/icons/actions/ic_trash.svg';
  static const icEdit = 'assets/svgs/icons/actions/ic_edit.svg';
  static const icMove = 'assets/svgs/icons/actions/ic_move.svg';
  static const icPin = 'assets/svgs/icons/actions/ic_pin.svg';
  static const icUnpin = 'assets/svgs/icons/actions/ic_unpin.svg';
  static const icShare = 'assets/svgs/icons/actions/ic_share.svg';
  static const icDownload = 'assets/svgs/icons/actions/ic_download.svg';
  static const icUpload = 'assets/svgs/icons/actions/ic_upload.svg';
  static const icRefresh = 'assets/svgs/icons/actions/ic_refresh.svg';
  static const icCheck = 'assets/svgs/icons/actions/ic_check.svg';
  static const icChevronRight =
      'assets/svgs/icons/actions/ic_chevron_right.svg';
  static const icChevronDown = 'assets/svgs/icons/actions/ic_chevron_down.svg';
  static const icExternalLink =
      'assets/svgs/icons/actions/ic_external_link.svg';

  // Features
  static const icQrScan = 'assets/svgs/icons/features/ic_qr_scan.svg';
  static const icDeploy = 'assets/svgs/icons/features/ic_deploy.svg';
  static const icAiChat = 'assets/svgs/icons/features/ic_ai_chat.svg';
  static const icImportRepo = 'assets/svgs/icons/features/ic_import_repo.svg';
  static const icNewProject = 'assets/svgs/icons/features/ic_new_project.svg';
  static const icPreview = 'assets/svgs/icons/features/ic_preview.svg';
  static const icFileExplorer =
      'assets/svgs/icons/features/ic_file_explorer.svg';
  static const icCodeEditor = 'assets/svgs/icons/features/ic_code_editor.svg';

  // Chat
  static const icLike = 'assets/svgs/icons/chat/ic_like.svg';
  static const icDislike = 'assets/svgs/icons/chat/ic_dislike.svg';
  static const icRegenerate = 'assets/svgs/icons/chat/ic_regenerate.svg';
  static const icMemoryBrain = 'assets/svgs/icons/chat/ic_memory_brain.svg';
  static const icThinking = 'assets/svgs/icons/chat/ic_thinking.svg';
  static const icSend = 'assets/svgs/icons/chat/ic_send.svg';

  // Status
  static const icSuccess = 'assets/svgs/icons/status/ic_success.svg';
  static const icError = 'assets/svgs/icons/status/ic_error.svg';
  static const icWarning = 'assets/svgs/icons/status/ic_warning.svg';
  static const icInfo = 'assets/svgs/icons/status/ic_info.svg';
  static const icOnline = 'assets/svgs/icons/status/ic_online.svg';
  static const icOffline = 'assets/svgs/icons/status/ic_offline.svg';

  // Files
  static const icFileDart = 'assets/svgs/icons/files/ic_file_dart.svg';
  static const icFileJs = 'assets/svgs/icons/files/ic_file_js.svg';
  static const icFileTs = 'assets/svgs/icons/files/ic_file_ts.svg';
  static const icFileHtml = 'assets/svgs/icons/files/ic_file_html.svg';
  static const icFileCss = 'assets/svgs/icons/files/ic_file_css.svg';
  static const icFileJson = 'assets/svgs/icons/files/ic_file_json.svg';
  static const icFileMd = 'assets/svgs/icons/files/ic_file_md.svg';
  static const icFileGeneric = 'assets/svgs/icons/files/ic_file_generic.svg';
  static const icFolder = 'assets/svgs/icons/files/ic_folder.svg';

  // Avatars
  static const avatarAiKrivana = 'assets/svgs/avatars/avatar_ai_krivana.svg';
  static const avatarUserDefault =
      'assets/svgs/avatars/avatar_user_default.svg';
  static const avatarUserPlaceholder =
      'assets/svgs/avatars/avatar_user_placeholder.svg';

  // AI Providers
  static const logoOpenAI = 'assets/svgs/providers/logo_openai.svg';
  static const logoAnthropic = 'assets/svgs/providers/logo_anthropic.svg';
  static const logoGemini = 'assets/svgs/providers/logo_google_gemini.svg';
  static const logoGroq = 'assets/svgs/providers/logo_groq.svg';
  static const logoTogetherAI = 'assets/svgs/providers/logo_together_ai.svg';
  static const logoOpenRouter = 'assets/svgs/providers/logo_openrouter.svg';
  static const logoCustomApi = 'assets/svgs/providers/logo_custom_api.svg';

  // Social
  static const logoGitHub = 'assets/svgs/social/logo_github.svg';
  static const logoVercel = 'assets/svgs/social/logo_vercel.svg';

  // Illustrations
  static const illustEmptyProjects =
      'assets/svgs/illustrations/illus_empty_projects.svg';
  static const illustEmptyChat =
      'assets/svgs/illustrations/illus_empty_chat.svg';
  static const illustNoConnection =
      'assets/svgs/illustrations/illus_no_connection.svg';
  static const illustSuccess =
      'assets/svgs/illustrations/illus_success_connect.svg';
  static const illustError = 'assets/svgs/illustrations/illus_error.svg';

  static String fileIcon(String extension) {
    return switch (extension.toLowerCase()) {
      'dart' => icFileDart,
      'js' => icFileJs,
      'ts' || 'tsx' => icFileTs,
      'jsx' => icFileJs,
      'html' || 'htm' => icFileHtml,
      'css' || 'scss' || 'sass' => icFileCss,
      'json' => icFileJson,
      'md' || 'mdx' => icFileMd,
      _ => icFileGeneric,
    };
  }
}

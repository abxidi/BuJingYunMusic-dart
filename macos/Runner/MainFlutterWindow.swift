import Cocoa
import FlutterMacOS
import AVFoundation

private let musicLibraryChannelName = "com.novapulse.mp3/music_library"
private let maxMusicScanCount = 500
private let audioExtensions: Set<String> = [
  "mp3", "m4a", "aac", "wav", "wave", "flac", "aif", "aiff", "ogg", "oga", "opus", "amr", "caf"
]
private var securityScopedFolders: [URL] = []

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    let channel = FlutterMethodChannel(
      name: musicLibraryChannelName,
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "scanAudioStore":
        result(scanDefaultMusicDirectory())
      case "pickAndScanFolder":
        result(pickAndScanFolder(attachedTo: self))
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}

private func scanDefaultMusicDirectory() -> [[String: String]] {
  guard let musicDirectory = FileManager.default.urls(
    for: .musicDirectory,
    in: .userDomainMask
  ).first else {
    return []
  }
  return scanMusicDirectory(musicDirectory, sourceLabel: "Mac / Music")
}

private func pickAndScanFolder(attachedTo window: NSWindow?) -> [[String: String]] {
  let panel = NSOpenPanel()
  panel.allowsMultipleSelection = false
  panel.canChooseDirectories = true
  panel.canChooseFiles = false
  panel.canCreateDirectories = false
  panel.prompt = "选择"
  panel.message = "选择一个包含本地音频文件的目录"

  let response = panel.runModal()
  guard response == .OK, let directory = panel.urls.first else {
    return []
  }

  if directory.startAccessingSecurityScopedResource() {
    securityScopedFolders.append(directory)
  }
  return scanMusicDirectory(directory, sourceLabel: "所选目录")
}

private func scanMusicDirectory(_ directory: URL, sourceLabel: String) -> [[String: String]] {
  let fileManager = FileManager.default
  let keys: [URLResourceKey] = [
    .isDirectoryKey,
    .localizedNameKey,
    .fileSizeKey,
  ]
  guard let enumerator = fileManager.enumerator(
    at: directory,
    includingPropertiesForKeys: keys,
    options: [.skipsHiddenFiles, .skipsPackageDescendants]
  ) else {
    return []
  }

  var scanned: [[String: String]] = []
  for case let fileURL as URL in enumerator {
    if scanned.count >= maxMusicScanCount {
      break
    }

    guard isAudioFile(fileURL) else {
      continue
    }

    let values = try? fileURL.resourceValues(forKeys: Set(keys))
    if values?.isDirectory == true {
      continue
    }

    let title = values?.localizedName ?? fileURL.lastPathComponent
    let parentName = fileURL.deletingLastPathComponent().lastPathComponent
    scanned.append([
      "title": title,
      "meta": "\(sourceLabel) / \(parentName.isEmpty ? "Music" : parentName)",
      "duration": readAudioDuration(fileURL),
      "size": formatSize(values?.fileSize ?? 0),
      "uri": fileURL.absoluteString,
    ])
  }
  return scanned
}

private func isAudioFile(_ url: URL) -> Bool {
  audioExtensions.contains(url.pathExtension.lowercased())
}

private func readAudioDuration(_ url: URL) -> String {
  let asset = AVURLAsset(url: url)
  let seconds = CMTimeGetSeconds(asset.duration)
  if seconds.isNaN || seconds <= 0 {
    return "--:--"
  }
  return formatDuration(milliseconds: Int(seconds * 1000))
}

private func formatDuration(milliseconds: Int) -> String {
  let totalSeconds = milliseconds / 1000
  let minutes = totalSeconds / 60
  let seconds = totalSeconds % 60
  return String(format: "%02d:%02d", minutes, seconds)
}

private func formatSize(_ bytes: Int) -> String {
  if bytes <= 0 {
    return "未知大小"
  }
  return String(format: "%.1f MB", Double(bytes) / 1024.0 / 1024.0)
}

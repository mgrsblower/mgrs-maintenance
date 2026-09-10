import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentInteractionControllerDelegate {
  private var docInteractionController: UIDocumentInteractionController?
  private var isChannelConfigured = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      configureInvoicePdfChannel(messenger: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let messenger = engineBridge.pluginRegistry.registrar(forPlugin: "InvoicePdfPlugin")?.messenger() {
      configureInvoicePdfChannel(messenger: messenger)
    }
  }

  private func configureInvoicePdfChannel(messenger: FlutterBinaryMessenger) {
    guard !isChannelConfigured else { return }
    isChannelConfigured = true

    let channel = FlutterMethodChannel(
      name: "com.mgrs.mgrs_maintenance/invoice_pdf",
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }

      switch call.method {
      case "saveInvoicePdf":
        guard let args = call.arguments as? [String: Any],
              let bytesData = args["bytes"] as? FlutterStandardTypedData,
              let fileName = args["fileName"] as? String else {
          result(FlutterError(code: "invalid_arguments", message: "Parameter tidak valid", details: nil))
          return
        }
        do {
          let path = try self.saveInvoicePdf(data: bytesData.data, fileName: fileName)
          result(path)
        } catch {
          result(FlutterError(code: "save_failed", message: error.localizedDescription, details: nil))
        }

      case "openInvoicePdf":
        guard let args = call.arguments as? [String: Any],
              let location = args["location"] as? String else {
          result(FlutterError(code: "invalid_arguments", message: "Location kosong", details: nil))
          return
        }
        self.openInvoicePdf(location: location)
        result(nil)

      case "shareInvoicePdf":
        guard let args = call.arguments as? [String: Any],
              let location = args["location"] as? String else {
          result(FlutterError(code: "invalid_arguments", message: "Location kosong", details: nil))
          return
        }
        self.shareInvoicePdf(location: location)
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func saveInvoicePdf(data: Data, fileName: String) throws -> String {
    let fileManager = FileManager.default
    guard let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
      throw NSError(domain: "MGRS", code: 1, userInfo: [NSLocalizedDescriptionKey: "Folder Dokumen tidak ditemukan"])
    }

    let mgrsDir = documentsUrl.appendingPathComponent("MGRS", isDirectory: true)
    if !fileManager.fileExists(atPath: mgrsDir.path) {
      try fileManager.createDirectory(at: mgrsDir, withIntermediateDirectories: true, attributes: nil)
    }

    let fileUrl = mgrsDir.appendingPathComponent(fileName)
    try data.write(to: fileUrl, options: .atomic)
    return fileUrl.path
  }

  private func openInvoicePdf(location: String) {
    let fileUrl = URL(fileURLWithPath: location)
    guard let rootVC = window?.rootViewController else { return }

    docInteractionController = UIDocumentInteractionController(url: fileUrl)
    docInteractionController?.delegate = self
    let success = docInteractionController?.presentPreview(animated: true) ?? false
    if !success {
      docInteractionController?.presentOptionsMenu(from: rootVC.view.bounds, in: rootVC.view, animated: true)
    }
  }

  private func shareInvoicePdf(location: String) {
    let fileUrl = URL(fileURLWithPath: location)
    guard let rootVC = window?.rootViewController else { return }

    let activityVC = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
    if let popover = activityVC.popoverPresentationController {
      popover.sourceView = rootVC.view
      popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }
    rootVC.present(activityVC, animated: true, completion: nil)
  }

  public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
    return window?.rootViewController ?? UIViewController()
  }
}


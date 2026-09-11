import Flutter
import UIKit
import QuickLook

class PdfPreviewItem: NSObject, QLPreviewItem {
    let previewItemURL: URL?
    let previewItemTitle: String?

    init(url: URL, title: String? = nil) {
        self.previewItemURL = url
        self.previewItemTitle = title ?? url.lastPathComponent
    }
}

class PdfPreviewDelegate: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    private let item: PdfPreviewItem
    var onDismiss: (() -> Void)?

    init(item: PdfPreviewItem) {
        self.item = item
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return item
    }

    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        onDismiss?()
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private var activePreviewDelegate: PdfPreviewDelegate?
    private var isChannelConfigured = false

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if let controller = window?.rootViewController as? FlutterViewController {
            configurePdfChannels(messenger: controller.binaryMessenger)
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        if let messenger = engineBridge.pluginRegistry.registrar(forPlugin: "InvoicePdfPlugin")?.messenger() {
            configurePdfChannels(messenger: messenger)
        }
    }

    private func configurePdfChannels(messenger: FlutterBinaryMessenger) {
        guard !isChannelConfigured else { return }
        isChannelConfigured = true

        // 1. Native PDF Channel (mgrs/native_pdf)
        let nativePdfChannel = FlutterMethodChannel(
            name: "mgrs/native_pdf",
            binaryMessenger: messenger
        )
        nativePdfChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            switch call.method {
            case "previewPdf":
                let args = call.arguments as? [String: Any]
                let path = args?["path"] as? String
                self.previewPdf(path: path, result: result)

            case "sharePdf":
                let args = call.arguments as? [String: Any]
                let path = args?["path"] as? String
                let title = args?["title"] as? String
                self.sharePdf(path: path, title: title, result: result)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // 2. Legacy Invoice PDF Channel (com.mgrs.mgrs_maintenance/invoice_pdf)
        let legacyChannel = FlutterMethodChannel(
            name: "com.mgrs.mgrs_maintenance/invoice_pdf",
            binaryMessenger: messenger
        )
        legacyChannel.setMethodCallHandler { [weak self] (call, result) in
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
                let args = call.arguments as? [String: Any]
                let location = args?["location"] as? String
                self.previewPdf(path: location, result: result)

            case "shareInvoicePdf":
                let args = call.arguments as? [String: Any]
                let location = args?["location"] as? String
                let fileName = args?["fileName"] as? String
                self.sharePdf(path: location, title: fileName, result: result)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func getTopViewController(base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? window?.rootViewController
        if let nav = root as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return getTopViewController(base: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return root
    }

    private func previewPdf(path: String?, result: @escaping FlutterResult) {
        guard let cleanPath = path?.trimmingCharacters(in: .whitespacesAndNewlines), !cleanPath.isEmpty else {
            result(FlutterError(code: "EMPTY_PATH", message: "Path file PDF tidak boleh kosong.", details: nil))
            return
        }

        let fileUrl = URL(fileURLWithPath: cleanPath)
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: fileUrl.path) else {
            result(FlutterError(code: "FILE_NOT_FOUND", message: "File PDF tidak ditemukan: \(cleanPath)", details: nil))
            return
        }

        guard fileUrl.pathExtension.lowercased() == "pdf" else {
            result(FlutterError(code: "NOT_A_PDF", message: "Format file bukan dokumen PDF yang valid.", details: nil))
            return
        }

        guard let topVC = getTopViewController() else {
            result(FlutterError(code: "PREVIEW_FAILED", message: "Tidak dapat menemukan UIViewController aktif.", details: nil))
            return
        }

        if topVC is QLPreviewController || topVC.presentedViewController is QLPreviewController {
            result(FlutterError(code: "ALREADY_PRESENTING", message: "Preview sedang ditampilkan.", details: nil))
            return
        }

        let previewItem = PdfPreviewItem(url: fileUrl)
        let delegate = PdfPreviewDelegate(item: previewItem)
        delegate.onDismiss = { [weak self] in
            self?.activePreviewDelegate = nil
        }
        self.activePreviewDelegate = delegate

        let previewVC = QLPreviewController()
        previewVC.dataSource = delegate
        previewVC.delegate = delegate

        topVC.present(previewVC, animated: true) {
            result(nil)
        }
    }

    private func sharePdf(path: String?, title: String?, result: @escaping FlutterResult) {
        guard let cleanPath = path?.trimmingCharacters(in: .whitespacesAndNewlines), !cleanPath.isEmpty else {
            result(FlutterError(code: "EMPTY_PATH", message: "Path file PDF tidak boleh kosong.", details: nil))
            return
        }

        let fileUrl = URL(fileURLWithPath: cleanPath)
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: fileUrl.path) else {
            result(FlutterError(code: "FILE_NOT_FOUND", message: "File PDF tidak ditemukan: \(cleanPath)", details: nil))
            return
        }

        guard let topVC = getTopViewController() else {
            result(FlutterError(code: "SHARE_FAILED", message: "Tidak dapat menemukan UIViewController aktif.", details: nil))
            return
        }

        if topVC is UIActivityViewController || topVC.presentedViewController is UIActivityViewController {
            result(FlutterError(code: "ALREADY_PRESENTING", message: "Share sheet sedang ditampilkan.", details: nil))
            return
        }

        let activityVC = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        topVC.present(activityVC, animated: true) {
            result(nil)
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
}

//
//  SafariWebExtensionHandler.swift
//  Shared (Extension)
//
//  Created by Buchet, Aurelien on 11.05.26.
//

import SafariServices
import os.log
#if os(macOS)
import AppKit
#endif

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    private enum MessageKey {
        static let command = "command"
        static let openExternal = "openExternal"
        static let url = "url"
    }

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        let profile: UUID?
        if #available(iOS 17.0, macOS 14.0, *) {
            profile = request?.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            profile = request?.userInfo?["profile"] as? UUID
        }

        let message: Any?
        if #available(iOS 15.0, macOS 11.0, *) {
            message = request?.userInfo?[SFExtensionMessageKey]
        } else {
            message = request?.userInfo?["message"]
        }

        os_log(.default, "Received native message: %@ (profile: %@)", String(describing: message), profile?.uuidString ?? "none")

        let payload = message as? [String: Any]
        let result = handleOpenExternalMessage(payload)

        let response = NSExtensionItem()
        let responsePayload: [String: Any] = result

        if #available(iOS 15.0, macOS 11.0, *) {
            response.userInfo = [ SFExtensionMessageKey: responsePayload ]
        } else {
            response.userInfo = [ "message": responsePayload ]
        }

        context.completeRequest(returningItems: [ response ], completionHandler: nil)
    }

    private func handleOpenExternalMessage(_ payload: [String: Any]?) -> [String: Any] {
        guard
            let payload,
            let command = payload[MessageKey.command] as? String,
            command == MessageKey.openExternal,
            let rawUrl = payload[MessageKey.url] as? String,
            let url = URL(string: rawUrl),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else {
            return [
                "ok": false,
                "error": "Invalid message payload"
            ]
        }

#if os(macOS)
        let didOpen = NSWorkspace.shared.open(url)
        return [
            "ok": didOpen,
            "error": didOpen ? "" : "NSWorkspace failed to open URL"
        ]
#else
        return [
            "ok": false,
            "error": "Unsupported platform"
        ]
#endif
    }

}

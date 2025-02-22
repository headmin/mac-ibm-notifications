//
//  AppDelegate.swift
//  IBM Notifier
//
//  Created by Jan Valentik on 18/06/2020.
//  Copyright © 2020 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//

import Cocoa
import os.log
import Signals

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let userNotificationController = UserNotificationController.shared
    let notificationDispatch = NotificationDispatch.shared
    let deepLinkEngine = DeepLinkEngine.shared
    let apnsController = APNSController.shared
    let efclController = EFCLController.shared
    let logger = Logger.shared
    var isConfigured: Bool = false

    private func configureApp(_ completion: @escaping () -> Void = {}) {
        guard !isConfigured else {
            completion()
            return
        }
        isConfigured = true
        NSApplication.shared.activate(ignoringOtherApps: true)
        self.notificationDispatch.startObservingForNotifications()
        self.efclController.parseArguments()
        completion()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Signals.trap(signal: .user(Int(SIGINT))) { _ in
            EFCLController.shared.applicationExit(withReason: .receivedSigInt)
        }
        configureApp()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        logger.log("IBM Notifier will terminate")
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        self.deepLinkEngine.agentTriggeredByDeepLink = true
        guard UserDefaults.standard.bool(forKey: "deeplinkSecurity") else {
            logger.log(.error, "You need to enable deep link security to use deep link")
            return
        }
        configureApp {
            for url in urls {
                self.logger.log("IBM Notifier was triggered by a URL", [url.absoluteString])
                self.deepLinkEngine.processURL(url)
            }
        }
    }

    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
        self.apnsController.agentTriggeredByAPNS = true
        configureApp {
            self.logger.log("IBM Notifier was triggered by a remote notification")
            self.apnsController.receivedRemoteNotification(with: userInfo)
        }
    }
}

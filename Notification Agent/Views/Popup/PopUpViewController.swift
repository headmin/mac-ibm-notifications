//
//  PopUpViewController.swift
//  IBM Notifier
//
//  Created by Jan Valentik on 18/06/2020.
//  Copyright © 2020 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//

import Cocoa
import os.log
import Foundation
import SwiftyMarkdown

class PopUpViewController: NSViewController {

    // MARK: - Static variables

    static var identifier: NSStoryboard.SceneIdentifier = .init(stringLiteral: "popUpViewController")

    // MARK: - Outlets

    @IBOutlet weak var iconView: NSImageView!
    @IBOutlet weak var helpButton: NSButton!
    @IBOutlet weak var mainButton: NSButton!
    @IBOutlet weak var secondaryButton: NSButton!
    @IBOutlet weak var tertiaryButton: NSButton!
    @IBOutlet weak var popupElementsStackView: NSStackView!

    // MARK: - Variables

    var notificationObject: NotificationObject!
    var timeoutTimer: Timer?
    var replyHandler = ReplyHandler.shared
    let logger = Logger.shared
    var shouldAllowCancel: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.mainButton.title = self.shouldAllowCancel ? "cancel_label".localized : self.notificationObject.mainButton.label
            }
        }
    }
    var accessoryView: NSView?

    // MARK: - Instance methods

    override func viewWillAppear() {
        super.viewWillAppear()
        configureView()
    }

    // MARK: - Private methods

    /// Configure the popup's window.
    private func configureView() {
        configureWindow()
        configureMainLabels()
        setIconIfNeeded()
        configureButtons()

        if let accessoryView = notificationObject?.accessoryView {
            configureAccessoryView(accessoryView)
        }

        checkStackViewLayout()
        setTimeoutIfNeeded()
    }

    /// Configure the bar title and the level for the popup's window.
    private func configureWindow() {
        self.title = notificationObject?.barTitle ?? ConfigurableParameters.defaultPopupBarTitle
        view.window?.level = (notificationObject?.alwaysOnTop ?? false) ? .floating : .normal
    }

    /// Set the title and the description of the popup if defined.
    private func configureMainLabels() {
        if let title = notificationObject?.title {
            let titleLabel = NSTextField(wrappingLabelWithString: title.localized)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            if let fontSize = titleLabel.font?.pointSize {
                titleLabel.font = .boldSystemFont(ofSize: fontSize)
            }
            self.popupElementsStackView.insertView(titleLabel, at: 0, in: .top)
        }

        if let subtitle = notificationObject?.subtitle {
            let textView = MarkdownTextView(withText: subtitle.localized)
            self.popupElementsStackView.insertView(textView, at: 0, in: .center)
        }
    }

    /// This method load and set the icon if a custom one was defined.
    private func setIconIfNeeded() {
        func loadIcon(from filePath: String) {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
               let image = NSImage(data: data) {
                iconView.image = image
            }
        }
        if let iconPath = notificationObject.iconPath,
           FileManager.default.fileExists(atPath: iconPath) {
            loadIcon(from: iconPath)
        } else if let defaultIconPath = ConfigurableParameters.defaultPopupIconPath,
                  FileManager.default.fileExists(atPath: defaultIconPath) {
            loadIcon(from: defaultIconPath)
        } else {
            iconView.image = NSImage(named: NSImage.Name("default_icon"))
        }
    }

    /// Configure and insert the related accessory view.
    /// - Parameter accessoryView: the defined accessory view.
    private func configureAccessoryView(_ accessoryView: NotificationAccessoryElement) {
        switch accessoryView.type {
        case .timer:
            guard let rawTime = notificationObject.timeout,
                  let time = Int(rawTime) else { return }
            let timerAccessoryView = TimerAccessoryView(withTimeInSeconds: time, label: accessoryView.payload)
            timerAccessoryView.translatesAutoresizingMaskIntoConstraints = false
            timerAccessoryView.delegate = self
            self.popupElementsStackView.insertView(timerAccessoryView, at: 0, in: .bottom)
        case .whitebox:
            let markdownTextView = MarkdownTextView(withText: accessoryView.payload.localized, drawsBackground: true)
            self.popupElementsStackView.insertView(markdownTextView, at: 0, in: .bottom)
        case .progressbar:
            let progressBarAccessoryView = ProgressBarAccessoryView(accessoryView.payload)
            self.popupElementsStackView.insertView(progressBarAccessoryView, at: 0, in: .bottom)
            progressBarAccessoryView.delegate = self
            self.secondaryButton.isHidden  = !(progressBarAccessoryView.isUserInteractionEnabled && notificationObject.secondaryButton != nil)
            self.shouldAllowCancel = progressBarAccessoryView.isUserInterruptionAllowed
            self.mainButton.isHidden = !(progressBarAccessoryView.isUserInterruptionAllowed || progressBarAccessoryView.isUserInteractionEnabled)
        case .image:
            guard let media = accessoryView.media, media.image != nil else { return }
            let imageAccessoryView = ImageAccessoryView(with: media)
            self.popupElementsStackView.insertView(imageAccessoryView, at: 0, in: .bottom)
        case .video:
            guard let media = accessoryView.media, media.player  != nil  else { return }
            let videoAccessoryView = VideoAccessoryView(with: media)
            self.popupElementsStackView.insertView(videoAccessoryView, at: 0, in: .bottom)
        case .input:
            let inputAccessoryView = InputAccessoryView(with: accessoryView.payload.localized)
            self.popupElementsStackView.insertView(inputAccessoryView, at: 0, in: .bottom)
            self.accessoryView = inputAccessoryView
        case .securedinput:
            let securedInputAccessoryView = InputAccessoryView(with: accessoryView.payload.localized, isSecured: true)
            self.popupElementsStackView.insertView(securedInputAccessoryView, at: 0, in: .bottom)
            self.accessoryView = securedInputAccessoryView
        }
    }

    /// Set the needed buttons in the popup's window.
    private func configureButtons() {
        self.helpButton.isHidden = notificationObject?.helpButton == nil

        let defaultTitle = ConfigurableParameters.defaultMainButtonLabel
        self.mainButton.title = notificationObject?.mainButton.label.localized ?? defaultTitle

        if let secondaryButtonLabel = notificationObject?.secondaryButton?.label {
            self.secondaryButton.isHidden = false
            self.secondaryButton.title = secondaryButtonLabel.localized
        }

        if let tertiaryButtonLabel = notificationObject?.tertiaryButton?.label {
            self.tertiaryButton.isHidden = false
            self.tertiaryButton.title = tertiaryButtonLabel.localized
        }
    }

    /// Check the stack view distribution based on the number of the arrangedSubviews.
    private func checkStackViewLayout() {
        if self.popupElementsStackView.arrangedSubviews.count == 1 {
            self.popupElementsStackView.distribution = .equalSpacing
        } else {
            self.popupElementsStackView.distribution = .gravityAreas
        }
    }

    /// If needed to set a timeout for the popup this method set the related actions and fire a timer.
    private func setTimeoutIfNeeded() {
        if let accessoryView = notificationObject?.accessoryView {
            guard accessoryView.type != .timer else { return }
        }
        if let timeoutString = notificationObject?.timeout, let timeout = Int(timeoutString) {
            timeoutTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeout),
                                                repeats: false, block: { [weak self] _ in
                                                    self?.triggerAction(ofType: .timeout)
            })
        } else if let defaultTimeout = ConfigurableParameters.defaultPopupTimeout {
            timeoutTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(defaultTimeout),
                                                repeats: false, block: { [weak self] _ in
                                                    self?.triggerAction(ofType: .timeout)
            })
        }
    }

    /// Invalidate and delete the existing timer.
    private func resetTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }

    /// Close the popup window.
    private func closeWindow() {
        resetTimer()
        view.window?.close()
    }

    private func triggerAction(ofType type: ReplyHandler.ReplyType) {
        replyHandler.handleResponse(ofType: type, for: notificationObject)
        switch type {
        case .main, .secondary, .timeout:
            closeWindow()
        default:
            break
        }
    }

    // MARK: - Actions

    /// User clicked the main button.
    @IBAction func didClickedMainButton(_ sender: NSButton) {
        if let accessoryView = accessoryView as? InputAccessoryView {
            print(accessoryView.inputValue)
        }
        self.triggerAction(ofType: shouldAllowCancel ? .cancel : .main)
    }

    /// User clicked the secondary button.
    @IBAction func didClickedSecondaryButton(_ sender: NSButton) {
        self.triggerAction(ofType: .secondary)
    }

    /// User clicked the tertiary button.
    @IBAction func didClickedTertiaryButton(_ sender: NSButton) {
        self.triggerAction(ofType: .tertiary)
    }

    /// User clicked the help button.
    @IBAction func didClickedHelpButton(_ sender: NSButton) {
        guard let helpButtonObject = notificationObject?.helpButton else { return }
        switch helpButtonObject.callToActionType {
        case .infopopup:
            let infos = InfoSection(fields: [InfoField(label: helpButtonObject.callToActionPayload)])
            let infoPopupViewController = InfoPopOverViewController(with: infos)
            self.present(infoPopupViewController,
                         asPopoverRelativeTo: sender.convert(sender.bounds, to: self.view),
                         of: self.view,
                         preferredEdge: .maxX,
                         behavior: .semitransient)
        default:
            self.triggerAction(ofType: .help)
        }
    }
}

/// TimerAccessoryViewDelegate methods implementation.
extension PopUpViewController: TimerAccessoryViewDelegate {
    func timerDidFinished(_ sender: TimerAccessoryView) {
        self.triggerAction(ofType: .main)
    }
}

/// ProgressBarAccessoryViewDelegate methods implementation.
extension PopUpViewController: ProgressBarAccessoryViewDelegate {
    func didFinishLoading(_ sender: ProgressBarAccessoryView) {
        DispatchQueue.main.async {
            self.shouldAllowCancel = false
            self.mainButton.isHidden = false
            if self.notificationObject.secondaryButton != nil {
                self.secondaryButton.isHidden = false
            }
        }
    }

    func didChangeEstimation(_ isIndeterminated: Bool) {
        if isIndeterminated {
            self.mainButton.title = notificationObject.mainButton.label
            self.secondaryButton.isHidden = notificationObject.secondaryButton != nil ? false : true
        } else {
            self.mainButton.title = "cancel_label".localized
            self.secondaryButton.isHidden = true
        }
    }
}

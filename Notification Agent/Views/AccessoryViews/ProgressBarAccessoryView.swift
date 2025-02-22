//
//  ProgressBarAccessoryView.swift
//  IBM Notifier
//
//  Created by Simone Martorelli on 10/13/20.
//  Copyright © 2020 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//

import Cocoa

/// The delegate that will communicate outside the event of the progress bar if needed.
protocol ProgressBarAccessoryViewDelegate: AnyObject {
    func didFinishLoading(_ sender: ProgressBarAccessoryView)
    func didChangeEstimation(_ isIndeterminated: Bool)

}

/// This view show a progress bar and handle the interactive UI updates for it.
class ProgressBarAccessoryView: NSView {

    // MARK: - Private variables

    private var containerWidth: CGFloat {
        return self.superview?.bounds.width ?? 0
    }
    private var progressBar: NSProgressIndicator!
    private var topMessageLabel: NSTextField!
    private var bottomMessageLabel: NSTextField!
    private var viewWidthAnchor: NSLayoutConstraint!
    private var shouldQuitObservation = false
    private var viewState: ProgressState!
    private var interactiveEFCLController: InteractiveEFCLController

    // MARK: - Public viariables

    var isIndeterminate: Bool {
        return viewState.isIndeterminate
    }
    var isUserInteractionEnabled: Bool {
        return viewState.isUserInteractionEnabled
    }
    var isUserInterruptionAllowed: Bool {
        return viewState.isUserInterruptionAllowed
    }

    // MARK: - Public variables
    weak var delegate: ProgressBarAccessoryViewDelegate?

    // MARK: - Initializers

    init(_ payload: String? = nil) {
        interactiveEFCLController = InteractiveEFCLController()
        super.init(frame: .zero)
        viewState = ProgressState(payload)
        interactiveEFCLController.delegate = self
        topMessageLabel = NSTextField(labelWithString: viewState.topMessage)
        topMessageLabel.lineBreakMode = .byTruncatingTail
        topMessageLabel.maximumNumberOfLines = 1
        topMessageLabel.font = NSFont.systemFont(ofSize: 12)
        topMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomMessageLabel = NSTextField(labelWithString: viewState.bottomMessage)
        bottomMessageLabel.lineBreakMode = .byTruncatingTail
        bottomMessageLabel.maximumNumberOfLines = 1
        bottomMessageLabel.alphaValue = 0.7225
        bottomMessageLabel.font = NSFont.systemFont(ofSize: 10)
        bottomMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        progressBar = NSProgressIndicator()
        progressBar.doubleValue = viewState.percent
        progressBar.isIndeterminate = viewState.isIndeterminate
        if viewState.isIndeterminate {
            self.progressBar.startAnimation(nil)
        }
        progressBar.style = .bar
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topMessageLabel)
        addSubview(progressBar)
        addSubview(bottomMessageLabel)
        topMessageLabel.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        topMessageLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 1).isActive = true
        topMessageLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        topMessageLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
        progressBar.topAnchor.constraint(equalTo: topMessageLabel.bottomAnchor, constant: 4).isActive = true
        progressBar.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        progressBar.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        progressBar.heightAnchor.constraint(equalToConstant: 10).isActive = true
        bottomMessageLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor).isActive = true
        bottomMessageLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 1).isActive = true
        bottomMessageLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        bottomMessageLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        bottomMessageLabel.heightAnchor.constraint(equalToConstant: 12).isActive = true
        adjustViewSize()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    deinit {
        interactiveEFCLController.stopObservingForProgressBarUpdates()
    }

    // MARK: - Instance methods

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        adjustViewSize()
        interactiveEFCLController.startObservingForProgressBarUpdates(viewState)
    }

    // MARK: - Private methods

    /// Adjust the view size based on the superview width.
    private func adjustViewSize() {
        viewWidthAnchor?.isActive = false
        viewWidthAnchor = progressBar.widthAnchor.constraint(equalToConstant: self.containerWidth)
        viewWidthAnchor.isActive = true
        progressBar.isBezeled = true
    }
}

extension ProgressBarAccessoryView: InteractiveEFCLControllerDelegate {
    /// Update the UI for the new state received.
    /// - Parameter newState: the new state to be showed.
    func didReceivedNewStateforProgressBar(_ newState: ProgressState) {
        DispatchQueue.main.async {
            self.viewState = newState
            self.progressBar.isIndeterminate = self.viewState.isIndeterminate
            if self.viewState.isIndeterminate {
                self.progressBar.startAnimation(nil)
            }
            NSAnimationContext.runAnimationGroup { (context) in
                context.duration = 0.2
                self.topMessageLabel.animator().stringValue = self.viewState.topMessage
                self.bottomMessageLabel.animator().stringValue = self.viewState.bottomMessage
                if !self.viewState.isIndeterminate {
                    self.progressBar.animator().doubleValue = self.viewState.percent
                }
                if self.viewState.percent >= 100 {
                    self.delegate?.didFinishLoading(self)
                }
            }
        }
    }

    /// Interactive updates ended.
    func didFinishedInteractiveUpdates() {
        defer {
            self.delegate?.didFinishLoading(self)
        }
        DispatchQueue.main.async {
            self.progressBar.isIndeterminate = false
            self.progressBar.doubleValue = 100
            self.progressBar.stopAnimation(nil)
        }
    }
}

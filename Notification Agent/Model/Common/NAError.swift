//
//  NAError.swift
//  IBM Notifier
//
//  Created by Simone Martorelli on 7/13/20.
//  Copyright © 2020 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//

import Foundation

enum NAError {
    case dataFormat(type: Enums.ModelError)
    case deepLinkHandling(type: Enums.DeepLinkHandlingError)
    case efclController(type: Enums.EFCLControllerError)

    class Enums { }
}

extension NAError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .dataFormat(let type):
            return type.localizedDescription
        case .deepLinkHandling(let type):
            return type.localizedDescription
        case .efclController(let type):
            return type.localizedDescription
        }
    }
    var efclExitReason: EFCLController.ExitReason {
        switch self {
        case .efclController(let type):
            return type.efclExitReason
        default:
            return .internalError
        }
    }
}

// MARK: - Model Errors

extension NAError.Enums {
    enum ModelError {
        case noTypeDefined
        case noInfoToShow
        case noButtonDefined
        case noHelpButtonAllowedInNotification
        case invalidJSONPayload
        case invalidJSONFilepath
        case invalidJSONDecoding(errorDescription: String)
    }
}

extension NAError.Enums.ModelError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noTypeDefined:
            return "No notification \"type\" parameter defined"
        case .noInfoToShow:
            return "No info to show for the desired UI type. Please check the documentation and make sure to define all the mandatory field for the desired UI type."
        case .noButtonDefined:
            return "No button defined"
        case .noHelpButtonAllowedInNotification:
            return "It's not allowed to define an help button in a \"banner\" UI type style."
        case .invalidJSONPayload:
            return "Invalid JSON payload."
        case .invalidJSONFilepath:
            return "Invalid JSON file path."
        case .invalidJSONDecoding(let errorDescription):
            return "Invalid JSON format: \(errorDescription)"
        }
    }
}

// MARK: - DeepLinkEngine Errors

extension NAError.Enums {
    enum DeepLinkHandlingError {
        case failedToGetComponents
        case unsupportedPath
        case noParametersFound
        case invalidToken
    }
}

extension NAError.Enums.DeepLinkHandlingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failedToGetComponents:
            return "Failed to get URL's components"
        case .unsupportedPath:
            return "URL's path is not supported"
        case .noParametersFound:
            return "Failed to get URL's parameters"
        case .invalidToken:
                return "Unauthorized request"
        }
    }
}

// MARK: - Execution From Command Line Controller Errors

extension NAError.Enums {
    enum EFCLControllerError {
        case invalidArgumentsSyntax
        case invalidArgumentsFormat
        case errorBuildingNotificationObject(description: String)
    }
}

extension NAError.Enums.EFCLControllerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidArgumentsSyntax:
            return "Invalid arguments syntax."
        case .invalidArgumentsFormat:
            return String(format: "Invalid argument syntax.")
        case .errorBuildingNotificationObject(let description):
            return String(format: "Error while trying to create notification object from arguments: %@.", description)
        }
    }
    var efclExitReason: EFCLController.ExitReason {
        switch self {
        case .invalidArgumentsSyntax:
            return .invalidArgumentsSyntax
        case .invalidArgumentsFormat:
            return .invalidArgumentFormat
        case .errorBuildingNotificationObject:
            return .invalidArgumentFormat
        }
    }
}

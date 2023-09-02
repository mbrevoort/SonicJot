//
//  SettingsViewModel.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/29/23.
//

import Foundation
import CloudKit
import Cocoa
import Combine

class SettingsViewModel: ObservableObject {
    @Published var settings: SettingsModel = SettingsModel.instance()
    var changeSink: AnyCancellable?

    
    init() {
        changeSink = settings.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }

    }
    
    
//    @Published var permissionStatus: Bool = false
//    @Published var isSignedInToiCLoud: Bool = false
//    @Published var error: String = ""
//    @Published var userName: String = ""
//
//    init() {
//        getiCloudStatus()
//        requestPermission()
//        fetchiCloudUserRecordID()
//    }
//
//
//    private func getiCloudStatus() {
//        CKContainer.default().accountStatus { [weak self] retrunedStatus, returnedError in
//            DispatchQueue.main.async {
//                switch retrunedStatus {
//                case .available:
//                    self?.isSignedInToiCLoud = true
//                case .noAccount:
//                    self?.error = CloudKitError.iCloudAccountNotFound.localizedDescription
//                case .couldNotDetermine:
//                    self?.error = CloudKitError.iCLoudAccountNotDetermined.localizedDescription
//                case .restricted:
//                    self?.error = CloudKitError.iCloudAccountRestricted.localizedDescription
//                default:
//                    self?.error = CloudKitError.iCLoudAccountUnknown.localizedDescription
//
//                }
//            }
//        }
//    }
//
//    enum CloudKitError: String, LocalizedError {
//        case iCloudAccountNotFound
//        case iCLoudAccountNotDetermined
//        case iCloudAccountRestricted
//        case iCLoudAccountUnknown
//    }
//
//    func requestPermission()  {
//        CKContainer.default().requestApplicationPermission([.userDiscoverability]) { [weak self] returnedStatus, returnedError in
//            DispatchQueue.main.async {
//                if returnedStatus == .granted {
//                    self?.permissionStatus = true
//                }
//            }
//        }
//    }
//
//    func fetchiCloudUserRecordID() {
//        CKContainer.default().fetchUserRecordID { [weak self] returnedID, returnedError in
//            if let id = returnedID {
//                self?.discoveriCloudUser(id: id)
//            }
//        }
//    }
//
//    func discoveriCloudUser(id: CKRecord.ID) {
//        CKContainer.default().discoverUserIdentity(withUserRecordID: id) { [weak self] returnedIdentity, returnedError in
//
//            DispatchQueue.main.async {
//                if let name = returnedIdentity?.nameComponents?.givenName {
//                    self?.userName = name
//                }
//            }
//        }
//    }
}

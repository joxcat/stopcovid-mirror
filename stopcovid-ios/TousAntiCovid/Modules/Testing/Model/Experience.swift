// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Experience.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 13/05/2020 - for the TousAntiCovid project.
//


import UIKit
import RealmSwift

final class Experience: Object {

    enum ExpType: String, CaseIterable {
        case bench = "newExpeditionController.type.bench"
        case room = "newExpeditionController.type.room"
        case field = "newExpeditionController.type.field"
        
        static var standard: Experience.ExpType { .room }
        
        var technicalValue: String {
            switch self {
            case .bench:
                return "bench"
            case .room:
                return "room"
            case .field:
                return "field"
            }
        }
        
    }
    
    @objc dynamic var code: String?
    @objc dynamic var type: String
    @objc dynamic var deviceName: String?
    @objc dynamic var testName: String?
    @objc dynamic var position: String?
    @objc dynamic var startDate: Date?
    @objc dynamic var endDate: Date?
    
    override class func primaryKey() -> String? {
        return "code"
    }
    
    override class func indexedProperties() -> [String] {
        return ["code"]
    }
    
    init(code: String?, type: Experience.ExpType, deviceName: String?, testName: String?, position: String?, startDate: Date?) {
        self.code = code
        self.type = type.rawValue
        self.deviceName = deviceName
        self.testName = testName
        self.position = position
        self.startDate = startDate
        super.init()
    }
    
    required init() {
        self.type = Experience.ExpType.standard.rawValue
        super.init()
    }
    
}

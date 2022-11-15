//
//  File.swift
//
//  Created by Aliaksandr Kiklevich on 10/8/19.
//  Copyright © 2019 kiklevich Alex. All rights reserved.
//

import Foundation
import RealmSwift

class TemplateRealm: IXPSRealm {
    
    // MARK: - Internal variables
    
    var workingQueue: DispatchQueue?
    var fileName: String = "Templates.realm"
    var realmTypes: [Object.Type] = [TransferRecentlyRealmObject.self, TransferTemplateRealmObject.self]
    
    // MARK: - Initialization
    
    required init() {
    }
    
    // MARK: - Max records
    
    func maxRecords(type: AnyClass?) -> Int {
        
        switch type.self {
            
        case is TransferRecentlyRealmObject.Type:
            return 5
            
        case is TransferTemplateRealmObject.Type:
            return 500
            
        default:
            return 0
        }
    }
    
    // MARK: - Realm Type
    
    func realmType(type: AnyClass?) -> Object.Type {
        
        switch type.self {
            
        case is TransferRecentlyRealmObject.Type:
            return TransferRecentlyRealmObject.self
            
        case is TransferTemplateRealmObject.Type:
            return TransferTemplateRealmObject.self
            
        default:
            return Object.self
        }
    }
    
    // MARK: - Sorting settings
    
    func sortingSettings(type: AnyClass?) -> (String, Bool)? {
        
        switch type.self {
            
        case is TransferRecentlyRealmObject.Type:
            return ("name", true)
            
        case is TransferTemplateRealmObject.Type:
            return ("name", true)
            
        default:
            return nil
        }
    }
    
    // MARK: - Migration
    
    var realmVersion: UInt64 {
        return 0
    }
    
    var migrationBlock: MigrationBlock? {
        return nil
    }
}

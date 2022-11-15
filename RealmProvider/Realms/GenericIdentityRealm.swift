//
//  GenericIdentityType.swift
//
//  Created by Aliaksandr Kiklevich on 31.03.22.
//  Copyright © 2022 kiklevich Alex. All rights reserved.
//

import Foundation
import RealmSwift

class GenericIdentityRealm: IXPSRealm {
    
    // MARK: - Internal variables
    
    var workingQueue: DispatchQueue? = DispatchQueue(label: "com.ewallet.realm.genericIdentity.queue",
                                                     qos: .userInteractive,
                                                     attributes: .concurrent,
                                                     autoreleaseFrequency: .workItem,
                                                     target: DispatchQueue.global(qos: .userInteractive))
    var fileName: String = "GenericIdentity.realm"
    var realmTypes: [Object.Type] = [GenericIdentityRealmObject.self]
    
    // MARK: - Initialization
    
    required init() {
    }
    
    // MARK: - Max records
    
    func maxRecords(type: AnyClass?) -> Int {
        
        switch type.self {
            
        case is GenericIdentityRealmObject.Type:
            return 3
            
        default:
            return 0
        }
    }
    
    // MARK: - Realm Type
    
    func realmType(type: AnyClass?) -> Object.Type {
        
        switch type.self {
            
        case is GenericIdentityRealmObject.Type:
            return GenericIdentityRealmObject.self
            
        default:
            return Object.self
        }
    }
    
    // MARK: - Sorting settings
    
    func sortingSettings(type: AnyClass?) -> (String, Bool)? {
        
        switch type.self {
            
        case is GenericIdentityRealmObject.Type:
            return ("encryptionType", true)
            
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

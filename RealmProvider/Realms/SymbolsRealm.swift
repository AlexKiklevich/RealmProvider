//
//  SymbolsRealm.swift
//
//  Created by Aliaksandr Kiklevich on 12/26/19.
//  Copyright © 2019 kiklevich Alex. All rights reserved.
//

import Foundation
import RealmSwift

class SymbolsRealm: IXPSRealm {
    
    // MARK: - Internal variables
    
    var workingQueue: DispatchQueue? = DispatchQueue(label: "com.ewallet.realm.symbols.queue",
                                                     qos: .userInteractive,
                                                     attributes: .concurrent,
                                                     autoreleaseFrequency: .workItem,
                                                     target: DispatchQueue.global(qos: .userInteractive))
    var fileName: String = "Symbols.realm"
    var realmTypes: [Object.Type] = [SymbolRealmObject.self]
    
    // MARK: - Initialization
    
    required init() {
    }
    
    // MARK: - Max records
    
    func maxRecords(type: AnyClass?) -> Int {
        
        switch type.self {
            
        case is SymbolRealmObject.Type:
            return 500
            
        default:
            return 0
        }
    }
    
    // MARK: - Realm Type
    
    func realmType(type: AnyClass?) -> Object.Type {
        
        switch type.self {
            
        case is SymbolRealmObject.Type:
            return SymbolRealmObject.self
            
        default:
            return Object.self
        }
    }
    
    // MARK: - Sorting settings
    
    func sortingSettings(type: AnyClass?) -> (String, Bool)? {
        
        switch type.self {
            
        case is SymbolRealmObject.Type:
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

//
//  LogRealm.swift
//
//  Created by Aliaksandr Kiklevich on 7/30/19.
//  Copyright © 2019 kiklevich Alex. All rights reserved.
//

import Foundation
import RealmSwift

class LogRealm: IXPSRealm {
    
    // MARK: - Private constansts
    
    private lazy var coreProvider: ICoreProvider = inject()
    
    // MARK: - Internal variables
    
    var workingQueue: DispatchQueue? = DispatchQueue(label: "com.ewallet.realm.log.queue",
                                                     qos: .background,
                                                     attributes: .concurrent,
                                                     autoreleaseFrequency: .workItem,
                                                     target: DispatchQueue.global(qos: .background))
    var fileName: String = "Log.realm"
    var realmTypes: [Object.Type] = [LogObject.self, LogFilterObject.self]
    
    // MARK: - Initialization
    
    required init() {
    }
    
    // MARK: - Max records
    
    func maxRecords(type: AnyClass?) -> Int {
        
        switch type.self {
            
        case is LogObject.Type:
            return 3000
            
        case is LogFilterObject.Type:
            return 1
            
        default:
            return 0
        }
    }
    
    // MARK: - Realm Type
    
    func realmType(type: AnyClass?) -> Object.Type {
        
        switch type.self {
            
        case is LogObject.Type:
            return LogObject.self
            
        case is LogFilterObject.Type:
            return LogFilterObject.self
            
        default:
            return Object.self
        }
    }
    
    // MARK: - Sorting settings
    
    func sortingSettings(type: AnyClass?) -> (String, Bool)? {
        
        switch type.self {
            
        case is LogObject.Type:
            return ("date", true)
            
        case is LogFilterObject.Type:
            return nil
            
        default:
            return nil
        }
    }
    
    // MARK: - Migration
    
    var realmVersion: UInt64 {
        return 1
    }
    
    var migrationBlock: MigrationBlock? {
        
        return { [unowned self] migration, oldSchemaVersion in
            
            if oldSchemaVersion < 1 {
                
                migration.enumerateObjects(ofType: LogObject.className()) { oldObject, newObject in
                    
                    if let oldObject = oldObject {
                        
                        newObject?["wallet"] = self.coreProvider.eWallet?.accountNumber ?? ""
                        
                        if let attachmentType = oldObject["attachmentType"] as? Int {
                            newObject?["attachmentType"] = attachmentType
                        }
                        if let filterType = oldObject["filterType"] as? Int {
                            newObject?["filterType"] = filterType
                        }
                        if let format = oldObject["format"] as? String {
                            newObject?["format"] = format
                        }
                        if let messageParams = oldObject["messageParams"] as? List<String> {
                            newObject?["messageParams"] = messageParams
                        }
                        if let date = oldObject["date"] as? Date {
                            newObject?["date"] = date
                        }
                    }
                }
            }
        }
    }
}

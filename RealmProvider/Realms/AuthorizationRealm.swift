//
//  AuthorizationRealm.swift
//
//  Created by Aliaksandr Kiklevich on 11/5/19.
//  Copyright © 2019 kiklevich Alex. All rights reserved.
//

import Foundation
import RealmSwift

class AuthorizationRealm: IXPSRealm {
    
    // MARK: - Private constansts
    
    private lazy var restApiProvider: IRestApiProvider = inject()
    
    // MARK: - Internal variables
    
    var workingQueue: DispatchQueue? = DispatchQueue(label: "com.ewallet.realm.authorization.entities.queue",
                                                     qos: .userInteractive,
                                                     autoreleaseFrequency: .workItem,
                                                     target: DispatchQueue.global(qos: .userInteractive))
    var fileName: String = "Authorization.realm"
    var realmTypes: [Object.Type] = [AuthorizationTokenRealmObject.self]
    
    // MARK: - Initialization
    
    required init() {}
    
    // MARK: - Max records
    
    func maxRecords(type: AnyClass?) -> Int {
        
        switch type.self {
            
        case is AuthorizationTokenRealmObject.Type:
            return 50
            
        default:
            return 0
        }
    }
    
    // MARK: - Realm Type

    func realmType(type: AnyClass?) -> Object.Type {
        
        switch type.self {
            
        case is AuthorizationTokenRealmObject.Type:
            return AuthorizationTokenRealmObject.self
            
        default:
            return Object.self
        }
    }
    
    // MARK: - Sorting settings
    
    func sortingSettings(type: AnyClass?) -> (String, Bool)? {
        
        switch type.self {
            
        case is AuthorizationTokenRealmObject.Type:
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
                
                migration.enumerateObjects(ofType: AuthorizationTokenRealmObject
                                            .className()) { oldObject, newObject in
                    
                    if let oldObject = oldObject {
                        
                        newObject?["mainServer"] = self.restApiProvider.mainServerUrl
                        
                        if let clientID = oldObject["clientID"] as? String {
                            newObject?["clientID"] = clientID
                        }
                        if let refreshBase64 = oldObject["refreshBase64"] as? String {
                            newObject?["refreshBase64"] = refreshBase64
                        }
                        if let expireDate = oldObject["expireDate"] as? Date {
                            newObject?["expireDate"] = expireDate
                        }
                        if let deviceSecret = oldObject["deviceSecret"] as? String {
                            newObject?["deviceSecret"] = deviceSecret
                        }
                        if let accessToken = oldObject["accessToken"] as? String {
                            newObject?["accessToken"] = accessToken
                        }
                        if let tokenType = oldObject["tokenType"] as? String {
                            newObject?["tokenType"] = tokenType
                        }
                        if let refreshToken = oldObject["refreshToken"] as? String {
                            newObject?["refreshToken"] = refreshToken
                        }
                        if let expiresIn = oldObject["expiresIn"] as? Int {
                            newObject?["expiresIn"] = expiresIn
                        }
                        if let issued = oldObject["issued"] as? String {
                            newObject?["issued"] = issued
                        }
                        if let expires = oldObject["expires"] as? String {
                            newObject?["expires"] = expires
                        }
                    }
                }
            }
        }
    }
}

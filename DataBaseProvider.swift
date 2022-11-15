//
//  DataBaseProvider.swift
//
//  Created by Aliaksandr Kiklevich on 11/5/19.
//  Copyright © 2019 kiklevich Alex. All rights reserved.
//

import Foundation

protocol IDataBaseProvider {
    
    var authorizationProvider: RealmProvider<AuthorizationRealm> {get}
    var logRealmProvider: RealmProvider<LogRealm> {get}
    var templateRealmProvider: RealmProvider<TemplateRealm> {get}
    var symbolsRealmProvider: RealmProvider<SymbolsRealm> {get}
    var genericIdentityRealmProvider: RealmProvider<GenericIdentityRealm> {get}
    
    func didEnterBackground()
}

class DataBaseProvider {
    
    // MARK: - Private constants
    
    private var _authorizationProvider: RealmProvider<AuthorizationRealm>?
    private var _logRealmProvider: RealmProvider<LogRealm>?
    private var _templateRealmProvider: RealmProvider<TemplateRealm>?
    private var _symbolsRealmProvider: RealmProvider<SymbolsRealm>?
    private var _genericIdentityRealmProvider: RealmProvider<GenericIdentityRealm>?
    
    // MARK: - Internal properties
    
    var authorizationProvider: RealmProvider<AuthorizationRealm> {
        
        guard let provider = _authorizationProvider else {
            
            let provider = RealmProvider<AuthorizationRealm>()
            _authorizationProvider = provider
            
            return provider
        }
        
        return provider
    }
    
    var logRealmProvider: RealmProvider<LogRealm> {
        
        guard let provider = _logRealmProvider else {
            
            let provider = RealmProvider<LogRealm>()
            _logRealmProvider = provider
            
            return provider
        }
        
        return provider
    }
    
    var templateRealmProvider: RealmProvider<TemplateRealm> {
        
        guard let provider = _templateRealmProvider else {
            
            let provider = RealmProvider<TemplateRealm>()
            _templateRealmProvider = provider
            
            return provider
        }
        
        return provider
    }
    
    var symbolsRealmProvider: RealmProvider<SymbolsRealm> {
        
        guard let provider = _symbolsRealmProvider else {
            
            let provider = RealmProvider<SymbolsRealm>()
            _symbolsRealmProvider = provider
            
            return provider
        }
        
        return provider
    }
    
    var genericIdentityRealmProvider: RealmProvider<GenericIdentityRealm> {
        
        guard let provider = _genericIdentityRealmProvider else {
            
            let provider = RealmProvider<GenericIdentityRealm>()
            _genericIdentityRealmProvider = provider
            
            return provider
        }
        
        return provider
    }
    
    // MARK: - Initialization
    
    init() {
    }
}

extension DataBaseProvider: IDataBaseProvider {
    
    func didEnterBackground() {
        
        _authorizationProvider?.didEnterBackground(failure: nil)
        _logRealmProvider?.didEnterBackground(failure: nil)
        _templateRealmProvider?.didEnterBackground(failure: nil)
        _symbolsRealmProvider?.didEnterBackground(failure: nil)
        _genericIdentityRealmProvider?.didEnterBackground(failure: nil)
    }
}

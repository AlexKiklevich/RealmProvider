//
//  MainRealmProvider.swift
//
//  Created by Aliaksandr Kiklevich on 7/30/19.
//  Copyright © 2019 kiklevich Alex. All rights reserved.
//

import Foundation
import RealmSwift

class RealmProvider<XPSRealm: IXPSRealm> {
    
    // MARK: - Private constants
    
    private let xpsRealm: XPSRealm = XPSRealm()
    
    private let workingQueue: DispatchQueue
    private let lockerQueue = DispatchQueue(label: "com.ewallet.realm.locker.queue")
    
    // MARK: - Private variables
    
    private var configuration: Realm.Configuration?
    private var resultsDictionary = [String : ThreadSafeReference<Results<Object>>]()
    
    // MARK: - Private properties
    
    private var privateContextRealm: Realm? {
        
        do {
            
            guard let config = configuration else {
                return nil
            }
            
            let realm = try Realm(configuration: config)
            realm.refresh()
            realm.autorefresh = true
            
            return realm
            
        } catch let error as NSError {
            print(error)
        }
        
        return nil
    }
    
    // MARK: - Initialization
    
    init() {
        
        if let queue = xpsRealm.workingQueue {
            
            workingQueue = queue
            
        } else {
            
            workingQueue = DispatchQueue(label: "com.ewallet.realm.working.queue",
                                         qos: .default,
                                         attributes: .concurrent,
                                         autoreleaseFrequency: .workItem,
                                         target: DispatchQueue.global(qos: .default))
        }
        
        configureRealm()
    }
    
    // MARK: - Private functions
    
    private func configureRealm() {
        
        var documentDirectory: URL?
        do {
            
            documentDirectory = try FileManager.default.url(for: .documentDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: false)
        } catch let error as NSError {
            print(error)
        }
        
        self.configuration = Realm.Configuration(fileURL: documentDirectory?.appendingPathComponent(xpsRealm.fileName),
                                                 schemaVersion: xpsRealm.realmVersion,
                                                 migrationBlock: xpsRealm.migrationBlock,
                                                 objectTypes: xpsRealm.realmTypes)
    }
    
    // MARK: - Private functions
    
    private func resultsDidUpdated(with type: Object.Type, entities: Results<Object>) {
        
        let key = NSStringFromClass(type.self)
        let reference = ThreadSafeReference(to: entities)
        
        lockerQueue.sync { [weak self] in
            
            self?.resultsDictionary[key] = reference
        }
    }
    
    private func sort(results: Results<Object>) -> Results<Object> {
        
        let typeOf = type(of: results)
        if let (keyPath, ascending) = xpsRealm.sortingSettings(type: typeOf.ElementType.self) {
            
            return results.sorted(byKeyPath: keyPath,
                                  ascending: ascending)
        } else {

            return results
        }
    }
    
    // MARK: - Read async
    
    private func readFromStore(type: Object.Type,
                               completion: ObjectsResolvedHandler?) {
        
        workingQueue.async { [weak self] in
            
            autoreleasepool {
                
                guard let realm =  self?.privateContextRealm else {
                    return
                }
                
                let realmObjects = { realm.objects(type) }()
                if let sorted = self?.sort(results: realmObjects) {
                    
                    self?.resultsDidUpdated(with: type, entities: sorted)
                    
                    completion?(self, ThreadSafeReference(to: sorted))
                    
                } else {
                    
                    self?.resultsDidUpdated(with: type, entities: realmObjects)
                    
                    completion?(self, ThreadSafeReference(to: realmObjects))
                }
            }
        }
    }
    
    // MARK: - Write async
    
    private func writeToStore<T : ThreadConfined>(object: T,
                                                  failure: ErrorHandler?,
                                                  block: @escaping ((Realm, T?) -> Void)) {
        
        if object.realm == nil {
            
            writeAsync(object: object,
                       failure: failure,
                       block: block)
        } else {
            
            writeAsync(withTradeSafeWrapped: object,
                       failure: failure,
                       block: block)
        }
    }
    
    private func writeAsync<T : ThreadConfined>(withTradeSafeWrapped object: T,
                                                failure: ErrorHandler?,
                                                block: @escaping ((Realm, T?) -> Void)) {
        
        let wrappedObj = ThreadSafeReference(to: object)
        
        workingQueue.async { [weak self] in
            
            autoreleasepool {
                do {
                    
                    guard let realm = self?.privateContextRealm else {
                        return
                    }
                    
                    let object = realm.resolve(wrappedObj)
                    
                    try realm.saveWrite(
                        {
                            block(realm, object)
                        }
                    )
                } catch {
                    failure?(error)
                }
            }
        }
    }
    
    private func writeAsync<T : ThreadConfined>(object: T,
                                                failure: ErrorHandler?,
                                                block: @escaping ((Realm, T?) -> Void)) {
        
        workingQueue.async { [weak self] in
            
            autoreleasepool {
                do {
                    
                    guard let realm = self?.privateContextRealm else {
                        return
                    }
                    
                    try realm.saveWrite ( {
                            
                            block(realm, object)
                        }
                    )
                } catch {
                    failure?(error)
                }
            }
        }
    }
    
    private func writeAsync<Collection: ThreadConfinedSequence, T: ThreadConfined>
        (withTradeSafeSequence sequence: Collection,
         failure: ErrorHandler?,
         block: @escaping ((Realm, T?) -> Void)) where Collection.Element == ThreadSafeReference<T> {
        
        workingQueue.async { [weak self] in
            
            autoreleasepool {
                do {
                    
                    guard let realm = self?.privateContextRealm else {
                        return
                    }
                    
                    for wrapped in sequence {
                        
                        if let element = realm.resolve(wrapped) {
                            
                            try  realm.saveWrite(
                                {
                                    block(realm, element)
                                }
                            )
                        }
                    }
                    
                } catch {
                    failure?(error)
                }
            }
        }
    }
    
    // MARK: - Clearing
    
    private func clear(withType type: Object.Type,
                       failure: ErrorHandler?) {
        
        workingQueue.async { [weak self] in
            
            autoreleasepool {
                
                self?.read(type: type, completion: { _, wrapped in
                    
                    guard let realm = self?.privateContextRealm else {
                        return
                    }
                    
                    guard let resolved = realm.resolve(wrapped) else {
                        return
                    }
                    
                    let objectsCount = resolved.count
                    let maxCount = self?.xpsRealm.maxRecords(type: type) ?? 0
                    
                    if objectsCount > maxCount {
                        
                        let absolute = abs(objectsCount - maxCount)
                        
                        let sequence = resolved.slicedArray(startIndex: 0,
                                                            endIndex: absolute-1)
                        do {
                            
                            try realm.saveWrite(
                                {
                                    realm.delete(sequence)
                                }
                            )
                            
                        } catch let error as NSError {
                            
                            print(error)
                        }
                        
                        self?.resultsDidUpdated(with: type, entities: resolved)
                    }
                }, failure: failure)
            }
        }
    }
}

// MARK: - IRealmProvider

extension RealmProvider: IRealmProvider {
    
    // MARK: - Resolving
    
    func resolve<T>(_ wrapped: ThreadSafeReference<T>) -> T? where T : ThreadConfined {
        
        guard let resolved = privateContextRealm?.resolve(wrapped) else {
            
            return nil
        }
        
        return resolved
    }
    
    // MARK: - Writing
    
    func write<Element: Object>(element: Element,
                                failure: ErrorHandler?) {
        
        let writeBlock: (Realm, Element?) -> Void = { realm, element in
            
            if let element = element {
                realm.add(element)
            }
        }
        
        writeToStore(object: element,
                     failure: failure,
                     block: writeBlock)
    }
    
    func write<Collection: ThreadConfinedSequence>(collection: Collection,
                                                   failure: ErrorHandler?)
        where Collection.Element == Object {
            
            let writeBlock: (Realm, Collection?) -> Void = { realm, collection in
                
                if let collection = collection {
                    
                    for element in collection {
                        
                        realm.add(element)
                    }
                }
            }
            
            writeAsync(object: collection, failure: failure, block: writeBlock)
    }
    
    func overwrite<Element: Object>(element: Element,
                                    failure: ErrorHandler?) {
        
        writeAsync(object: element,
                   failure: { error in
                    print(error)
        },
                   block: { realm, element in
                    
                    if let element = element {
                        realm.add(element, update: .modified)
                    }
        })
    }
    
    // MARK: - Reading
    
    func read(type: Object.Type,
              completion: ObjectsResolvedHandler?,
              failure: ErrorHandler?) {
        
        let typeString = NSStringFromClass(type.self)
        
        if let wrapped = resultsDictionary[typeString],
            !wrapped.isInvalidated {
            
            if  let resolved = resolve(wrapped) {
                
                resultsDidUpdated(with: type, entities: resolved)
                
                weak var welf = self
                
                completion?(welf ,ThreadSafeReference(to: sort(results: resolved)))
            }
            
        } else {
            
            readFromStore(type: type, completion: completion)
        }
    }
    
    // MARK: - Deletion
    
    func delete<Element: Object>(element: Element,
                                 failure: ErrorHandler?) {
        
        let deleteBlock: (Realm, Element?) -> Void = { realm, element in
            
            if let element = element {
                realm.delete(element)
            }
        }
        
        writeToStore(object: element,
                     failure: failure,
                     block: deleteBlock)
    }
    
    func delete<Element: Object>(elements: Results<Element>,
                                 failure: ErrorHandler?) {
        
        let deleteBlock: (Realm, Results<Element>?) -> Void = { realm, elements in
            
            if let elements = elements {
                realm.delete(elements)
            }
        }
        
        writeToStore(object: elements,
                     failure: failure,
                     block: deleteBlock)
    }
    
    func delete<Collection: ThreadConfinedSequence,
        Element: Object>(collection: Collection,
                         failure: ErrorHandler?)
        where Collection.Element == ThreadSafeReference<Element> {
            
            let deleteBlock: (Realm, Element?) -> Void = { realm, element in
                
                if let element = element {
                    realm.delete(element)
                }
            }
            
            writeAsync(withTradeSafeSequence: collection,
                       failure: failure,
                       block: deleteBlock)
    }
    
    func deleteAll(completion: (() -> Void)?,
                   completionQueue: DispatchQueue,
                   failure: ErrorHandler?) {
        
        workingQueue.async { [weak self] in
            
            autoreleasepool {
                
                do {
                    
                    guard let realm = self?.privateContextRealm else {
                        return
                    }
                    
                    try realm.saveWrite(
                        {
                            realm.deleteAll()
                            
                            completionQueue.async {
                                completion?()
                            }
                        }
                    )
                } catch let error {
                    
                    failure?(error)
                }
            }
        }
    }
    
    // MARK: - Application life cycle
    
    func didEnterBackground(failure: ErrorHandler?) {
        
        for type in xpsRealm.realmTypes {
            
            clear(withType: type,
                  failure: failure)
        }
    }
}

// MARK: - Save writing

private extension Realm {
    
    func saveWrite(_ block: (() throws -> Void)) throws {
        
        if self.isInWriteTransaction {
            try block()
        } else {
            try self.write(block)
        }
    }
}

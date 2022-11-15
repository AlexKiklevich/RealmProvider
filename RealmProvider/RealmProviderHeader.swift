//
//  RealmProviderHeader.swift
//
//  Created by Aliaksandr Kiklevich on 12/19/19.
//  Copyright © 2019 kiklevich Alex. All rights reserved.
//

import Foundation
import RealmSwift

typealias ErrorHandler = ((_ error : Swift.Error) -> Void)
typealias ObjectsResolvedHandler = (IRealmProvider?, ThreadSafeReference<Results<Object>>) -> Void

protocol IRealmObservation {
    
    func realmObservation()
    func realmObservationInvalidation()
}

protocol IRealmProvider {
    
    func resolve<T: ThreadConfined>(_ wrapped: ThreadSafeReference<T>) -> T?
    
    func read(type: Object.Type,
              completion: ObjectsResolvedHandler?,
              failure: ErrorHandler?)
    
    func write<Element: Object>(element: Element,
                                failure: ErrorHandler?)
    func write<Collection: ThreadConfinedSequence>(collection: Collection,
                                                   failure: ErrorHandler?)
        where Collection.Element == Object
    
    func overwrite<Element: Object>(element: Element,
                                    failure: ErrorHandler?)
    
    func delete<Element: Object>(element: Element,
                                 failure: ErrorHandler?)
    func delete<Element: Object>(elements: Results<Element>,
                                 failure: ErrorHandler?)
    func delete<Collection: ThreadConfinedSequence, Element: Object>(collection: Collection,
                                                                     failure: ErrorHandler?)
        where Collection.Element == ThreadSafeReference<Element>
    func deleteAll(completion: (() -> Void)?,
                   completionQueue: DispatchQueue,
                   failure: ErrorHandler?)
    
    func didEnterBackground(failure: ErrorHandler?)
}

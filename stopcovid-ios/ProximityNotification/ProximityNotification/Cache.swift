/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/14 - for the TousAntiCovid project
 */

import Foundation

final class Cache<Key: Hashable, Value>: NSObject, NSCacheDelegate {
    
    private let cache = NSCache<KeyWrapper, Entry>()
    
    private let expirationDelay: TimeInterval
    
    private var keys = Set<Key>()
    
    private let dispatchQueue = DispatchQueue(label: UUID().uuidString, attributes: .concurrent)
    
    init(expirationDelay: TimeInterval = .infinity) {
        self.expirationDelay = expirationDelay
        
        super.init()
        
        cache.delegate = self
    }
    
    deinit {
        cache.delegate = nil
    }
    
    subscript(key: Key) -> Value? {
        get {
            return value(forKey: key)
        }
        set {
            if let value = newValue {
                setValue(value, forKey: key)
            } else {
                removeValue(forKey: key)
            }
        }
    }
    
    func setValue(_ value: Value, forKey key: Key) {
        let expirationDate = Date(timeIntervalSinceNow: expirationDelay)
        let entry = Entry(key: key, value: value, expirationDate: expirationDate)
        cache.setObject(entry, forKey: KeyWrapper(key))
        dispatchQueue.async(flags: .barrier) {
            self.keys.insert(key)
        }
    }
    
    func value(forKey key: Key) -> Value? {
        guard let entry = cache.object(forKey: KeyWrapper(key)) else {
            return nil
        }
        
        guard Date() < entry.expirationDate else {
            removeValue(forKey: key)
            
            return nil
        }
        
        return entry.value
    }
    
    func removeValue(forKey key: Key) {
        cache.removeObject(forKey: KeyWrapper(key))
    }
    
    func removeAllValues() {
        cache.removeAllObjects()
    }
    
    func removeExpiredValues() {
        dispatchQueue.sync {
            keys.forEach { key in
                _ = self.value(forKey: key)
            }
        }
    }
    
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject object: Any) {
        guard let entry = object as? Entry else {
            return
        }
        
        dispatchQueue.async(flags: .barrier) {
            self.keys.remove(entry.key)
        }
    }
}

private extension Cache {
    
    final class KeyWrapper: NSObject {
        
        let key: Key
        
        init(_ key: Key) {
            self.key = key
        }
        
        override var hash: Int {
            return key.hashValue
        }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let wrapper = object as? KeyWrapper else {
                return false
            }
            
            return wrapper.key == key
        }
    }
}

private extension Cache {
    
    final class Entry {
        
        let key: Key
        
        let value: Value
        
        let expirationDate: Date
        
        init(key: Key, value: Value, expirationDate: Date) {
            self.key = key
            self.value = value
            self.expirationDate = expirationDate
        }
    }
}

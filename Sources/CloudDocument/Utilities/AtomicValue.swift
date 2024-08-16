//
//  AtomicValue.swift
//  TextEditor
//
//  Created by 孟超 on 2024/8/15
//


#if canImport(Foundation)
import Foundation
/// A property wrapper to ensure thread safety for a stored property.
///
/// This property wrapper is only applicable to stored properties of struct or immutable class types. It uses `NSLock` internally to ensure thread safety for the property.
///
/// > If you want to access the property without locking, you can use the `projectedValue` of this property wrapper. However, this may lead to data races.
@propertyWrapper
final class AtomicValue<Value: Sendable>: @unchecked Sendable {
    private var storage: Value
    private let lock: NSLocking
    public var wrappedValue: Value {
        get {
            self.lock.lock()
            defer {
                self.lock.unlock()
            }
            return self.storage
        }
        set {
            self.lock.lock()
            self.storage = newValue
            self.lock.unlock()
        }
    }
    public var projectedValue: ((Value) -> Value) -> () {
        get {
            self.withAtomicProcess
        }
    }
    public var unsafeValue: Value {
        self.storage
    }
    
    private func withAtomicProcess(closure: (Value) -> Value) {
        self.lock.lock()
        self.storage = closure(self.storage)
        self.lock.unlock()
    }
    
    /// Initialize the current property wrapper with the specified lock type.
    public init(_ lock: Lock, defaultValue: Value) {
        self.storage = defaultValue
        switch lock {
            case .NSLock:
                self.lock = NSLock()
            case .NSConditionLock:
                self.lock = NSConditionLock()
            case .NSRecursiveLock:
                self.lock = NSRecursiveLock()
        }
    }
    
    /// Initialize the current property wrapper with the specified lock type.
    public init<T>(_ lock: Lock, defaultValue: T? = nil) where Value == T? {
        self.storage = defaultValue
        switch lock {
            case .NSLock:
                self.lock = NSLock()
            case .NSConditionLock:
                self.lock = NSConditionLock()
            case .NSRecursiveLock:
                self.lock = NSRecursiveLock()
        }
    }
    
    public enum Lock {
        case NSLock
        case NSConditionLock
        case NSRecursiveLock
    }
    
}
#endif

//
//  LYNetworkLock.swift
//
//  Copyright (c) 2017 LYNetwork https://github.com/ZakariyyaSv/LYNetwork
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import Darwin

// MARK: - Synchronized Methods
public func lysynchronized(_ lock: AnyObject, f:()->()) {
  objc_sync_enter(lock)
  f()
  objc_sync_exit(lock)
}


// MARK: - Lock Protocols
public protocol Lockable {
  func lock()
}

public protocol Unlockable {
  func unlock()
}

public protocol Waitable {
  /// whether or not to succeed in waiting a thread
  func wait() -> Bool
}

public protocol SignalSendable {
  /// whether or not to succeed in awaking a thread
  func signal() -> Bool
}


// MARK: - Mutex
/// posix thread mutex wrapper class
public class Mutex {
  /// mutex object pointer
  fileprivate let mutex: UnsafeMutablePointer<pthread_mutex_t>
  
  /// condition object pointer
  fileprivate let condition: UnsafeMutablePointer<pthread_cond_t>
  
  /// attribute object pointer
  fileprivate let attribute: UnsafeMutablePointer<pthread_mutexattr_t>
  
  // MARK: Initializer
  public init() {
    
    mutex = UnsafeMutablePointer.allocate(capacity: MemoryLayout<pthread_mutex_t>.size)
    condition = UnsafeMutablePointer.allocate(capacity: MemoryLayout<pthread_cond_t>.size)
    attribute = UnsafeMutablePointer.allocate(capacity: MemoryLayout<pthread_mutexattr_t>.size)
    
    pthread_mutexattr_init(attribute)
    pthread_mutexattr_settype(attribute, PTHREAD_MUTEX_RECURSIVE)
    pthread_mutex_init(mutex, attribute)
    pthread_cond_init(condition, nil)
    
  }
  
  // MARK: Deinitializer
  deinit {
    pthread_cond_destroy(condition);
    pthread_mutexattr_destroy(attribute)
    pthread_mutex_destroy(mutex)
  }
  
}

// MARK: Lock Protocols Implementation
extension Mutex : Lockable {
  public func lock() {
    pthread_mutex_lock(mutex)
  }
}

extension Mutex : Unlockable {
  public func unlock() {
    pthread_mutex_unlock(mutex)
  }
}

extension Mutex : Waitable {
  public func wait() -> Bool {
    return pthread_cond_wait(condition, mutex) == 0
  }
}

extension Mutex : SignalSendable {
  public func signal() -> Bool {
    return pthread_cond_signal(condition) == 0
  }
}



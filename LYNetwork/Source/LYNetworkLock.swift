//
//  LYNetworkLock.swift
//  LYNetwork
//
//  Created by zakariyyasv on 2017/6/23.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation
import Darwin

/**
 lock method protocol
 */
public protocol Lockable {
  /**
   lock a thread
   */
  func lock()
}

public protocol Unlockable {
  /**
   unlock a thread
   */
  func unlock()
}

public protocol Waitable {
  /**
   wait a thread
   
   - returns: whether or not to succeed in waiting a thread
   */
  func wait() -> Bool
}

public protocol SignalSendable {
  /**
   send a signal to thread locking/blocking system
   
   - returns: whether or not to succeed in awaking a thread
   */
  func signal() -> Bool
}

/**
 posix thread mutex wrapper class
 */
public class Mutex {
  /// mutex object pointer
  fileprivate let mutex: UnsafeMutablePointer<pthread_mutex_t>
  
  /// condition object pointer
  fileprivate let condition: UnsafeMutablePointer<pthread_cond_t>
  
  /// attribute object pointer
  fileprivate let attribute: UnsafeMutablePointer<pthread_mutexattr_t>
  
  /**
   initializer
   
   - returns: mutex class instance
   */
  public init() {
    
    mutex = UnsafeMutablePointer.allocate(capacity: MemoryLayout<pthread_mutex_t>.size)
    condition = UnsafeMutablePointer.allocate(capacity: MemoryLayout<pthread_cond_t>.size)
    attribute = UnsafeMutablePointer.allocate(capacity: MemoryLayout<pthread_mutexattr_t>.size)
    
    pthread_mutexattr_init(attribute)
    pthread_mutexattr_settype(attribute, PTHREAD_MUTEX_RECURSIVE)
    pthread_mutex_init(mutex, attribute)
    pthread_cond_init(condition, nil)
    
  }
  
  /**
   deinitializer
   */
  deinit {
    pthread_cond_destroy(condition);
    pthread_mutexattr_destroy(attribute)
    pthread_mutex_destroy(mutex)
  }
  
}

/**
 extend Mutex class to Lockable protocol
 */
extension Mutex : Lockable {
  
  /**
   lock a thread
   */
  public func lock() {
    
    pthread_mutex_lock(mutex)
    
  }
  
}

/**
 extend Mutex class to Lockable protocol
 */
extension Mutex : Unlockable {
  
  /**
   unlock a thread
   */
  public func unlock() {
    
    pthread_mutex_unlock(mutex)
    
  }
  
}

/**
 extend Mutex class to Waitable protocol
 */
extension Mutex : Waitable {
  /**
   wait a thread until signal()
   
   - returns: whether or not succeed in waiting a thread
   */
  public func wait() -> Bool {
    
    return pthread_cond_wait(condition, mutex) == 0
    
  }
}

/**
 extend Mutex class to SignalSendable protocol
 */
extension Mutex : SignalSendable {
  /**
   send a signal to the waiting thread
   
   - returns: whether or not succeed in sending a signal to a thread
   */
  public func signal() -> Bool {
    
    return pthread_cond_signal(condition) == 0
    
  }
  
}

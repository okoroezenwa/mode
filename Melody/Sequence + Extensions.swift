//
//  Sequence + Extensions.swift
//  Mode
//
//  Created by Ezenwa Okoro on 01/03/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import Foundation

enum ReduceBreakConditionError<Result>: Error {
    
    case stopExecutionWith(Result)
}

enum MapBreakConditionError<T>: Error {
    
    case stopExecutionWith([T])
}

enum CompactMapBreakConditionError<ElementOfResult>: Error {
    
    case stopExecutionWith([ElementOfResult])
}

enum FilterMapBreakConditionError<Element>: Error {
    
    case stopExecutionWith([Element])
}

extension Sequence {
    
    func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Self.Iterator.Element) throws -> Result, until executionShouldStop: () -> Bool) rethrows -> Result {

        do {
            return try reduce(initialResult, {
                
                    if executionShouldStop() {
                        
                        throw ReduceBreakConditionError.stopExecutionWith($0)
                        
                    } else {
                        
                        return try nextPartialResult($0, $1)
                    }
                }
            )
        
        } catch ReduceBreakConditionError<Result>.stopExecutionWith(let result) {
            
                return result
        }
    }
    
    func map<T>(_ transform: (Self.Element) throws -> T, until executionShouldStop: () -> Bool) rethrows -> [T] {
        
        do {
            
            return try map({
                
                if executionShouldStop() {
                    
                    throw MapBreakConditionError.stopExecutionWith([try transform($0)])
                    
                } else {
                    
                    return try transform($0)
                }
            })
        
        } catch MapBreakConditionError<T>.stopExecutionWith(let result) {
            
            return result
        }
    }
    
    func compactMap<ElementOfResult>(_ transform: (Self.Element) throws -> ElementOfResult?, until executionShouldStop: () -> Bool) rethrows -> [ElementOfResult] {
        
        do {
            
            return try compactMap({
                
                if executionShouldStop() {
                    
                    throw CompactMapBreakConditionError<ElementOfResult>.stopExecutionWith([try? transform($0)].compactMap({ value in value }))
                    
                } else {
                    
                    return try transform($0)
                }
            })
        
        } catch CompactMapBreakConditionError<ElementOfResult>.stopExecutionWith(let result) {
            
            return result
        }
    }

    func filter(_ isIncluded: (Self.Element) throws -> Bool, until executionShouldStop: () -> Bool) rethrows -> [Self.Element] {
        
        do {
            
            return try filter({
                
                if executionShouldStop() {
                    
                    throw FilterMapBreakConditionError<Element>.stopExecutionWith([$0])
                    
                } else {
                    
                    return try isIncluded($0)
                }
            })
        
        } catch FilterMapBreakConditionError<Element>.stopExecutionWith(let result) {
            
            return result
        }
    }
}

//
//  MPMediaQuery+Other.m
//  Mode
//
//  Created by Ezenwa Okoro on 07/02/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

#import "MPMediaQuery+Other.h"

@implementation MPMediaQuery (Other)

-(MPMediaQuery *)queryFromItems:(NSArray<MPMediaItem *> *)items
{
    SEL selector = NSSelectorFromString(@"initWithEntities:entityType:");
    
    if ([self respondsToSelector:selector]) {
        
        NSMethodSignature * signature = [self methodSignatureForSelector:selector];
        NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:signature];
        
        [invocation setTarget:self];
        [invocation setSelector:selector];
        [invocation setArgument:&items atIndex:2];
        
        int32_t arg = MPMediaGroupingTitle;
        [invocation setArgument:&arg atIndex:3];
        
        [invocation invoke];
        
        MPMediaQuery * __unsafe_unretained tempQuery;
        [invocation getReturnValue:&tempQuery];
        MPMediaQuery * item = tempQuery;
        
        return item;
        
    } else {
        
        return NULL;
    }
}


@end

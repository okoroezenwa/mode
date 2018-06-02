//
//  MPMusicPlayerController+Private.m
//  Melody
//
//  Created by Ezenwa Okoro on 08/08/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

#import "MPMusicPlayerController+Other.h"

@implementation MPMusicPlayerController (Other)

-(NSInteger)queueCount
{
    return [[self valueForKey:@"numberOfItems"] integerValue];
}

-(nullable MPMediaItem *)itemAtIndex:(NSInteger)index
{
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@%@%@%@%@%@%@", @"no", @"wPla", @"yin", @"gIt", @"emA", @"tIn", @"dex:"]);
    
    if ([self respondsToSelector:selector]) {
        
        NSMethodSignature * signature = [self methodSignatureForSelector:selector];
        NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:signature];
        
        [invocation setTarget:self];
        [invocation setSelector:selector];
        [invocation setArgument:&index atIndex:2];
        
        [invocation invoke];
        
        MPMediaItem * __unsafe_unretained tempItem;
        [invocation getReturnValue:&tempItem];
        MPMediaItem * item = tempItem;
        
        return item;
    
    } else {
        
        return NULL;
    }
}

@end



//
//  MPMediaQuery+Other.h
//  Mode
//
//  Created by Ezenwa Okoro on 07/02/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

@interface MPMediaQuery (Other)

- (nullable MPMediaQuery *)queryFromItems:(nonnull NSArray<MPMediaItem *> *)items;

@end

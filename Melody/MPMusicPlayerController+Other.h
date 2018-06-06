//
//  MPMusicPlayerController+Private.h
//  Melody
//
//  Created by Ezenwa Okoro on 08/08/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

@interface MPMusicPlayerController (Other)

- (nullable MPMediaItem *)itemAtIndex:(NSInteger)index;
- (NSInteger)queueCount;

@end

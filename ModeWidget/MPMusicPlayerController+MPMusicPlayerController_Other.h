//
//  MPMusicPlayerController+MPMusicPlayerController_Other.h
//  Melody
//
//  Created by Ezenwa Okoro on 02/08/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

@interface MPMusicPlayerController (MPMusicPlayerController_Other)

- (nullable MPMediaItem *)itemAtIndex:(NSInteger)index;
- (NSInteger)queueCount;

@end

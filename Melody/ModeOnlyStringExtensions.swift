//
//  ModeOnlyStringExtensions.swift
//  Mode
//
//  Created by Ezenwa Okoro on 10/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

extension String {
    
    enum LyricsTitleRemovalCategory { case brackets, punctuation, censoredWords, ampersands }
    enum LyricsTextType { case title, artist }
    
    var roundedBracketsRemoved: String {
        
        if let startIndex = index(of: "("), let endIndex = index(of: ")") {
            
            var string = self
            string.removeSubrange(startIndex...endIndex)
            
            return string
        }
        
        return self
    }
    
    var squareBracketsRemoved: String {
        
        if let startIndex = index(of: "["), let endIndex = index(of: "]") {
            
            var string = self
            string.removeSubrange(startIndex...endIndex)
            
            return string
        }
        
        return self
    }
    
    var punctuationRemoved: String {
        
        return replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "'", with: "")
    }
    
    var censoredWordsReplaced: String {
        
        return replacingOccurrences(of: "f**k", with: "fuck").replacingOccurrences(of: "f*ck", with: "fuck").replacingOccurrences(of: "s**t", with: "shit").replacingOccurrences(of: "b*tch", with: "bitch")
    }
    
    var ampersandsReplaced: String {
        
        return replacingOccurrences(of: "&", with: "")
    }
    
    func remove(_ category: LyricsTitleRemovalCategory, from type: LyricsTextType) -> String {
        
        switch (category, type) {
            
            case (.brackets, .title) where Mode.removeTitleBrackets,
                 (.brackets, .artist) where Mode.removeArtistBrackets: return roundedBracketsRemoved.squareBracketsRemoved
            
            case (.censoredWords, .title) where Mode.replaceTitleCensoredWords,
                 (.censoredWords, .artist) where Mode.replaceArtistCensoredWords: return censoredWordsReplaced
            
            case (.punctuation, .title) where Mode.removeTitlePunctuation,
                 (.punctuation, .artist) where Mode.removeArtistPunctuation: return punctuationRemoved
            
            case (.ampersands, .title) where Mode.removeTitleAmpersands,
                 (.ampersands, .artist) where Mode.removeArtistAmpersands: return ampersandsReplaced
            
            default: return self
        }
    }
}

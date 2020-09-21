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
        
        if let startIndex = firstIndex(of: "("), let endIndex = firstIndex(of: ")") {
            
            var string = self
            string.removeSubrange(startIndex...endIndex)
            
            return string
        }
        
        return self
    }
    
    var squareBracketsRemoved: String {
        
        if let startIndex = firstIndex(of: "["), let endIndex = firstIndex(of: "]") {
            
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
    
    var containingBracketsRemoved: String {
        
        return replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
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
    
    func lyricsRemovalsApplied(for type: LyricsTextType) -> String {
        
        if isInDebugMode {
            
            return remove(.brackets, from: type).remove(.punctuation, from: type).remove(.censoredWords, from: type).remove(.ampersands, from: type)
        
        } else {
            
            return remove(.punctuation, from: type).remove(.censoredWords, from: type).remove(.ampersands, from: type).containingBracketsRemoved
        }
    }
    
    func replacing(_ pattern: String, with template: String, options: NSRegularExpression.Options = []) -> String {

        guard let regex = try? NSRegularExpression.init(pattern: pattern, options: options) else { return self }

        return regex.stringByReplacingMatches(in: self, options: [], range: NSRange.init(startIndex..., in: self), withTemplate: template)
    }
}

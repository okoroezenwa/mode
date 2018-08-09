//
//  LyricsViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 06/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit
import SwiftSoup

class LyricsViewController: UIViewController {

    @IBOutlet var textView: MELTextView! {
        
        didSet {
            
            textView.textContainerInset = UIEdgeInsets.init(top: 10, left: 5, bottom: 10, right: 5)
            textView.scrollIndicatorInsets = UIEdgeInsets.init(top: 10, left: 5, bottom: 10, right: 5)
            textView.textAlignment = textAlignment
        }
    }
    @IBOutlet var locationButton: MELButton!
    @IBOutlet var saveButton: MELButton!
    @IBOutlet var spacerView: UIView!
    @IBOutlet var activityIndicator: MELActivityIndicatorView!
    @IBOutlet var bottomStackView: UIStackView!
    @IBOutlet var unavailableLabel: MELLabel!
    
    #warning("Needs localisation update")
    var textAlignment: NSTextAlignment = .left
    
    var item: MPMediaItem? {
        
        didSet {
            
            guard item != oldValue, let item = item else { return }
            
            if item.validLyrics.isEmpty {
                
                textView.isHidden = true
                unavailableLabel.isHidden = true
                activityIndicator.startAnimating()
                
                if oldValue != nil {
                
                    updateBottomView(to: .hidden)
                }
                
                getLyrics()
                
            } else {
                
                activityIndicator.stopAnimating()
                unavailableLabel.isHidden = true
                textView.contentOffset = .zero
                textView.text = item.validLyrics
                textView.isHidden = false
                
                locationButton.setImage(#imageLiteral(resourceName: "Offline14"), for: .normal)
                locationButton.setTitle("on device", for: .normal)
                
                updateBottomView(to: .visible, animated: oldValue == nil)
            }
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        updateBottomView(to: .hidden, animated: false)
    }
    
    func updateBottomView(to state: VisibilityState, animated: Bool = true) {
        
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            
            self.bottomStackView.alpha = state == .hidden ? 0 : 1
            self.bottomStackView.transform = state == .hidden ? .init(translationX: 0, y: 36) : .identity
        })
    }
    
    func getLyrics() {
        
        let token = "Xn2cLRvTA6EIfuTt8NE4jBiiqf579ocFAwQ5xzlEPkO11Kfo3MW0LGgsm6MtfeAl"
        let base = "https://api.genius.com"
        
        guard let title = item?.validTitle.lowercased().roundedBracketsRemoved.squareBracketsRemoved.punctuationRemoved.censoredWordsReplaced, let artist = item?.validArtist.lowercased().roundedBracketsRemoved.squareBracketsRemoved.replacingOccurrences(of: "&", with: "") else { return }
        
        var request = URLRequest.init(url: URL.init(string: base + "/search")!)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let text = title + " " + artist
        
        let parameters = ["q": text]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            
            if let error = error {
                
                print(error)
                
                DispatchQueue.main.async { self.displayUavailable() }
                
                return
            }
            
            do {
                
                let genius = try JSONDecoder().decode(Genius.self, from: data!)
                
                DispatchQueue.main.async {
                    
                    let url = genius.response.hits.first(where: { hit in Set(["Translations", "Tracklist", "[Credits]"]).contains(where: { hit.result.fullTitle.contains($0) }).inverted && (hit.result.title.similarityTo(title, fuzziness: 0.4) >= 0.5 || hit.result.artist.name.similarityTo(artist, fuzziness: 0.4) >= 0.5) })?.result.url
                    
                    self.downloadHTML(from: url)
                }
                
            } catch let error {
                
                print(error)
                
                DispatchQueue.main.async { self.displayUavailable() }
            }
        })
        
        task.resume()
    }
    
    func downloadHTML(from urlString: String?) {
        
        guard let url = URL(string: urlString ?? "") else {
            
            if isInDebugMode {
                
                UniversalMethods.banner(withTitle: "Invalid URL").show(for: 0.3)
            }
            
            self.displayUavailable()
            
            return
        }
        
        DispatchQueue.global(qos: .utility).async {
            
            do {
                
                let html = try String.init(contentsOf: url)
                
                let document = try SwiftSoup.parse(html)
                document.outputSettings().prettyPrint(pretty: false)
                try document.select("br").append("\\n")
                try document.select("p").prepend("\\n\\n")
//                let new = try document.html().replacingOccurrences(of: "\\\\n", with: "\n")
//
//                if let newDoc = try SwiftSoup.clean(new, .none()) {
//
//                    let doc = try SwiftSoup.parse(newDoc)
//                    doc.outputSettings().prettyPrint(pretty: false)
//
//                    document = doc
//                }
                
                UniversalMethods.performInMain { self.parse(document) }
                
            } catch let error {
                
                DispatchQueue.main.async {
                    
                    if isInDebugMode {
                    
                        UniversalMethods.banner(withTitle: "\(error)").show(for: 1)
                    }

                    self.displayUavailable()
                }
            }
        }
    }
    
    func parse(_ document: Document) {
        
        do {
            
            let elements: Elements = try document.select("body")
            
            if let text = try elements.first()?.text().components(separatedBy: "\\n\\n")[1].replacingOccurrences(of: "\\n ", with: "\n").replacingOccurrences(of: "More on Genius", with: "\\") {
                
                activityIndicator?.stopAnimating()
                unavailableLabel?.isHidden = true
                textView.contentOffset = .zero
                
                textView?.text = String(text.prefix(upTo: text.index(of: "\\") ?? text.endIndex))
                
                textView?.isHidden = false
                
                locationButton?.setImage(#imageLiteral(resourceName: "Web"), for: .normal)
                locationButton?.setTitle("genius.com", for: .normal)
                
                updateBottomView(to: .visible)
            
            } else {
            
                displayUavailable()
            }
            
        } catch let error {
            
            displayUavailable()
            
            if isInDebugMode {
            
                UniversalMethods.banner(withTitle: "\(error)").show(for: 1)
            }
        }
    }
    
    func displayUavailable() {
        
        activityIndicator.stopAnimating()
        unavailableLabel.isHidden = false
        textView.isHidden = true
        
        updateBottomView(to: .hidden)
    }
}

// MARK: - Genius Codables
struct Genius: Codable {
    
    let response: Response
}

struct Response: Codable {
    
    let hits: [Hit]
}

struct Hit: Codable {
    
    let result: Result
}

struct Result: Codable {
    
    enum CodingKeys: String, CodingKey {
        
        case url
        case title
        case artist = "primary_artist"
        case fullTitle = "full_title"
    }
    
    let url: String
    let title: String
    let artist: Artist
    let fullTitle: String
}

struct Artist: Codable {
    
    let name: String
}

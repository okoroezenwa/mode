//
//  NewOptionsViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 29/04/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController, SongActionable, Boldable, AlbumTransitionable, ArtistTransitionable, PlaylistTransitionable, GenreTransitionable, ComposerTransitionable, PreviewTransitionable, EntityVerifiable, InfoLoading, BorderButtonContaining, AlbumArtistTransitionable, FilterContaining, ArtworkModifying {

    @IBOutlet var collectionView: MELCollectionView!
    @IBOutlet var playButton: MELButton!
    @IBOutlet var actionsButton: MELButton! {
        
        didSet {
            
            let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(showSettings(with:)))
            gr.minimumPressDuration = longPressDuration
            actionsButton.addGestureRecognizer(gr)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: gr))
        }
    }
    @IBOutlet var shuffleButton: MELButton!
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet var previousButton: MELButton!
    @IBOutlet var nextButton: MELButton!
    
    enum Context {
        
        case song(location: Context.Location, at: Int, within: [MPMediaItem])
        case album(at: Int, within: [MPMediaItemCollection])
        case collection(kind: AlbumBasedCollectionKind, at: Int, within: [MPMediaItemCollection])
        case playlist(at: Int, within: [MPMediaPlaylist])
        
        enum Location { case list, queue(loaded: Bool, index: Int?) }
        
        var entity: Entity {
            
            switch self {
                
                case .song: return .song
                
                case .album: return .album
                
                case .playlist: return .playlist
                
                case .collection(let kind, _, _): return kind.entity
            }
        }
    }
    
    enum EntityState { case single, combined(previousIndex: Int) }
    
    lazy var applicableSections = InfoSection.applicableSections(for: self.context.entity)
    lazy var sections = self.prepareSections()
    
    var headerView: InfoCollectionReusableView! {
        
        didSet {
            
            guard firstLaunch else { return }
            
            updateCornersAndShadows()
            prepareViews()
            
            headerView.addToView.tapAction = .init(action: #selector(SongActionManager.showActionsForAll(_:)), target: songManager)
            headerView.queueView.tapAction = .init(action: #selector(addToQueue), target: self)
            headerView.insertView.tapAction = .init(action: #selector(addSongs), target: self)
        }
    }
    
    var artworkImageView: UIImageView! { return headerView.artworkImageView }
    var artworkContainer: UIView! { return headerView.artworkContainer }
    var titleButton: MELButton! { return headerView.titleButton }
    var alternateButton1: MELButton! { return headerView.alternateButton1 }
    var alternateButton2: MELButton! { return headerView.alternateButton2 }
    var alternateButton3: MELButton! { return headerView.alternateButton3 }
    var addedLabel: MELLabel! { return headerView.addedLabel }
    var playedLabel: MELLabel! { return headerView.playedLabel }
    var genreButton: MELButton! { return headerView.genreButton }
    var compilationButton: MELButton! { return headerView.compilationButton }
    var albumArtistButton: MELButton! { return headerView.albumArtistButton }
    var composerButton: MELButton! { return headerView.composerButton }
    var copyrightLabel: MELLabel! { return headerView.copyrightLabel }
    var lyricsTextView: MELTextView! { return headerView.lyricsTextView }
    var groupingLabel: MELLabel! { return headerView.groupingLabel }
    var commentsLabel: MELLabel! { return headerView.commentsLabel }
    var durationLabel: MELLabel! { return headerView.durationLabel }
    var trackLabel: MELLabel! { return headerView.trackLabel }
    var playlistsButton: MELButton! { return headerView.playlistsButton }
    var playlistsActivityIndicator: MELActivityIndicatorView! { return headerView.playlistsActivityIndicator }
    var playlistsBorderView: MELBorderView! { return headerView.playlistsBorderView }
    var queueButton: MELButton! { return headerView.queueView.button }
    var insertButton: MELButton! { return headerView.insertView.button }
    var addToButton: MELButton! { return headerView.addToView.button }
    var queueStackView: UIStackView! { return headerView.queueStackView }
    var explicitButton: MELButton! { return headerView.explicitButton }
    var entityRatingStackView: UIStackView! { return headerView.entityRatingStackView }
    var addedTitleLabel: MELLabel! { return headerView.addedTitleLabel }
    var playsTitleLabel: MELLabel! { return headerView.playsTitleLabel }
    var bpmLabel: MELLabel! { return headerView.bpmLabel }
    var skipsLabel: MELLabel! { return headerView.skipsLabel }
    var updatedLabel: MELLabel! { return headerView.updatedLabel }
    var skipsTitleLabel: MELLabel! { return headerView.skipsTitleLabel }
    
    var albumButton: MELButton? { return alternateButton2 }
    var artistButton: MELButton? { return alternateButton1 }
    
    var editButton: MELButton! {
        
        get { return (parent as? PresentedContainerViewController)?.rightButton }
        
        set { }
    }
    
//    var relevantWidth = screenWidth - 12
    var artwork: UIImage?
    var topArtwork: UIImage?
    
    var borderedButtons = [BorderedButtonView?]()
    
    let width = (screenWidth - 12) / 3
    
    var headerHeight: CGFloat = 0
    var lyricsOffset: CGFloat = 0
    
    let topViewHeight: CGFloat = 156
    let buttonsHeight: CGFloat = 62
    let singleLineHeight: CGFloat = 50
    let infoHeight: CGFloat = 76
    let lyricsLabelHeight: CGFloat = 40
    let lyricsInset: CGFloat = 16
    var lyricsTextViewHeight: CGFloat = 0
    
    var currentItem: MPMediaItem? {
        
        didSet {
            
            if case .song = context { } else { currentItem = nil }
        }
    }
    var currentAlbum: MPMediaItemCollection?
    var artistQuery: MPMediaQuery?
    var albumQuery: MPMediaQuery?
    var playlistQuery: MPMediaQuery?
    var composerQuery: MPMediaQuery?
    var genreQuery: MPMediaQuery?
    var albumArtistQuery: MPMediaQuery?
    var viewController: UIViewController?
    var isCurrentlyTopViewController = false
    var context = Context.song(location: .queue(loaded: false, index: 0), at: 0, within: [musicPlayer.nowPlayingItem].compactMap({ $0 }))
    var tempContext: Context?
    var entityState = EntityState.single
    var container: ContainerViewController? { return appDelegate.window?.rootViewController as? ContainerViewController }
    weak var filterContainer: (UIViewController & FilterContainer)?
    
    lazy var query: MPMediaQuery = { return self.getQuery() }()
    lazy var queries: [MPMediaQuery] = { return self.getQueries() }()
    
    var actionableSongs: [MPMediaItem] {
        
        switch entityState {
            
            case .single:
            
                switch context {
                    
                    case .song(location: _, at: let index, within: let items): return [items[index]]
                        
                    case .album, .collection, .playlist: return query.items ?? []
                }
            
            case .combined(previousIndex: _):
            
                switch context {
                    
                    case .song(location: _, at: _, within: let items): return items
                        
                    case .album, .collection, .playlist: return query.items ?? []
                }
            
        }
    }
    var applicableActions: [SongAction] {
        
        var actions = [SongAction.collect, .newPlaylist, .addTo]
        
        if case .song(location: _, at: let index, within: let items) = context, !items[index].existsInLibrary {
            
            actions.insert(.library, at: 1)
        }
        
        return actions
    }
    lazy var songManager: SongActionManager = { return SongActionManager.init(actionable: self) }()
    var otherEntities = [Entity]()
    var showLyrics = false
    var boldableLabels: [TextContaining?] { return [titleButton.titleLabel, alternateButton3.titleLabel, alternateButton1.titleLabel, alternateButton2.titleLabel, addedLabel, playedLabel, genreButton.titleLabel, albumArtistButton.titleLabel, composerButton.titleLabel, copyrightLabel, groupingLabel, lyricsTextView, commentsLabel, durationLabel, trackLabel, playlistsButton.titleLabel, compilationButton.titleLabel, explicitButton.titleLabel] }
    var firstLaunch = true
    
    let formatter: DateFormatter = {
        
        let formatter = DateFormatter.init()
        formatter.dateFormat = "dd MMM yyyy - HH:mm"
        
        return formatter
    }()
    
    lazy var playlists = [MPMediaPlaylist]()
    lazy var imageOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Image Operation Queue"
        
        
        return queue
    }()
//    lazy var queueOperationQueue: OperationQueue = {
//        
//        let queue = OperationQueue()
//        queue.name = "Queue Operation Queue"
//        
//        
//        return queue
//    }()
    lazy var imageCache: ImageCache = {
        
        let cache = ImageCache()
        cache.name = "Image Cache"
        cache.countLimit = 100
        
        return cache
    }()
    var operation: BlockOperation?
    var queueOperation: BlockOperation?
    lazy var operations = [IndexPath: Operation]()
    @objc lazy var infoOperations = InfoOperations()
    @objc let infoCache: InfoCache = {
        
        let cache = InfoCache()
        cache.name = "Info Cache"
        cache.countLimit = 2500
        
        return cache
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        view.layoutIfNeeded()
        
        notifier.addObserver(self, selector: #selector(updateForGeneralChange), name: .infoTextSizesChanged, object: nil)
        
        notifier.addObserver(self, selector: #selector(updateForCloudChange), name: .iCloudVisibilityChanged, object: nil)
        
        notifier.addObserver(self, selector: #selector(updateCornersAndShadows), name: .cornerRadiusChanged, object: nil)
        
        if let context = tempContext {
            
            self.context = context
        }
        
        if case .song = context {
            
            notifier.addObserver(self, selector: #selector(updateForGeneralChange), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer)
        }
        
        editButton.addTarget(songManager, action: #selector(SongActionManager.toggleEditing(_:)), for: .touchUpInside)
        
        notifier.addObserver(self, selector: #selector(prepareViews), name: UIApplication.willEnterForegroundNotification, object: UIApplication.shared)
        
        collectionView.register(UINib.init(nibName: "PlaylistCollectionCell", bundle: nil), forCellWithReuseIdentifier: "playlistCell")
        
        let hold = UILongPressGestureRecognizer.init(target: self, action: #selector(getInfo(_:)))
        hold.minimumPressDuration = longPressDuration
        hold.delegate = self
        collectionView.addGestureRecognizer(hold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))
        
        prepareTapGestures()
        
        registerForPreviewing(with: self, sourceView: collectionView)
        
        if #available(iOS 10.0, *) {
            
            collectionView.prefetchDataSource = self
        }
    }
    
    func prepareTapGestures() {
        
        let tapTitle = UITapGestureRecognizer.init(target: self, action: #selector(viewInContext))
        titleButton.superview?.addGestureRecognizer(tapTitle)
        
        let tapAlt1 = UITapGestureRecognizer.init(target: self, action: #selector(alternateButton1Action))
        alternateButton1.superview?.addGestureRecognizer(tapAlt1)
        
        let tapAlt2 = UITapGestureRecognizer.init(target: self, action: #selector(alternateButton2Action))
        alternateButton2.superview?.addGestureRecognizer(tapAlt2)
        
        let tapGenre = UITapGestureRecognizer.init(target: self, action: #selector(genreButtonAction))
        genreButton.superview?.addGestureRecognizer(tapGenre)
        
        let tapComposer = UITapGestureRecognizer.init(target: self, action: #selector(composerButtonAction))
        composerButton.superview?.addGestureRecognizer(tapComposer)
        
        let tapAlbumArtist = UITapGestureRecognizer.init(target: self, action: #selector(albumArtistButtonAction))
        albumArtistButton.superview?.addGestureRecognizer(tapAlbumArtist)
    }
    
    func prepareSections() -> [(InfoSection, String)] {
        
        return visibleInfoItems.filter({ applicableSections.contains($0) }).map({ ($0, "-") })
    }
    
    @objc func getInfo(_ sender: UILongPressGestureRecognizer) {
        
        guard sender.state == .began else { return }
        
        if let indexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)) {
            
            Transitioner.shared.showInfo(from: self, with: .playlist(at: indexPath.row, within: playlists))
        
        } else {
            
            if case .song = context, composerButton.superview?.bounds.contains(sender.location(in: composerButton.superview)) == true, let collections = composerQuery?.collections, collections.isEmpty.inverted {
                
                Transitioner.shared.showInfo(from: self, with: .collection(kind: .composer, at: 0, within: collections))
            
            } else if case .song = context, albumArtistButton.superview?.bounds.contains(sender.location(in: albumArtistButton.superview)) == true, let collections = albumArtistQuery?.collections, collections.isEmpty.inverted {
                
                Transitioner.shared.showInfo(from: self, with: .collection(kind: .albumArtist, at: 0, within: collections))
            
            } else if genreButton.superview?.bounds.contains(sender.location(in: genreButton.superview)) == true, let collections = genreQuery?.collections, collections.isEmpty.inverted {
                
                if case .playlist = context { return }
                
                if case .collection = context { return }
                
                Transitioner.shared.showInfo(from: self, with: .collection(kind: .genre, at: 0, within: collections))
            
            } else if alternateButton1.superview?.bounds.contains(sender.location(in: alternateButton1.superview)) == true {
                
                switch context {
                    
                    case .song:
                    
                        if let collections = artistQuery?.collections, collections.isEmpty.inverted {
                            
                            Transitioner.shared.showInfo(from: self, with: .collection(kind: .artist, at: 0, within: collections))
                        }
                    
                    case .album(at: let index, within: let albums):
                        
                        if let song = albums[index].representativeItem, let collections = (albumArtistsAvailable || song.isCompilation ? albumArtistQuery : artistQuery)?.collections, collections.isEmpty.inverted {
                            
                            Transitioner.shared.showInfo(from: self, with: .collection(kind: albumArtistsAvailable || song.isCompilation ? .albumArtist : .artist, at: 0, within: collections))
                        }
                    
                    default:
                    
                        guard let albumsQuery = (query.copy() as? MPMediaQuery)?.grouped(by: .album), let albums = albumsQuery.collections else { return }
                    
                        Transitioner.shared.showInfo(from: self, with: .album(at: 0, within: albums))
                }
            
            } else if alternateButton2.superview?.bounds.contains(sender.location(in: alternateButton2.superview)) == true {
                
                switch context {
                    
                    case .song:
                        
                        if let collections = albumQuery?.collections, collections.isEmpty.inverted {
                            
                            Transitioner.shared.showInfo(from: self, with: .album(at: 0, within: collections))
                        }
                    
                    default:
                    
                        guard let songsQuery = (query.copy() as? MPMediaQuery), let songs = songsQuery.items else { return }
                        
                        Transitioner.shared.showInfo(from: self, with: .song(location: .list, at: 0, within: songs))
                }
            
            } else if alternateButton3.superview?.bounds.contains(sender.location(in: alternateButton3.superview)) == true {
                
                switch context {
                    
                    case .song: break
                    
                    default:
                        
                        guard let artistsQuery = (query.copy() as? MPMediaQuery)?.grouped(by: .artist), let collections = artistsQuery.collections else { return }
                        
                        Transitioner.shared.showInfo(from: self, with: .collection(kind: .artist, at: 0, within: collections))
                }
            }
        }
    }
    
    @objc func updateForCloudChange() {
        
        query = getQuery()
        updateForGeneralChange()
    }
    
    @objc func updateForGeneralChange() {
        
        UIView.transition(with: collectionView, duration: 0.3, options: .transitionCrossDissolve, animations: { self.prepareViews() }, completion: nil)
    }
    
    @objc func updateCornersAndShadows() {
        
        (infoCornerRadius ?? cornerRadius).updateCornerRadius(on: artworkImageView.layer, width: artworkImageView.bounds.width, entityType: context.entity, globalRadiusType: cornerRadius)
        
        UniversalMethods.addShadow(to: artworkContainer, radius: 8, opacity: 0.2, shouldRasterise: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        collectionView.flashScrollIndicators()
    }
    
    func noteFilterState() {
        
        if let filterVC = filterContainer {
            
            filterVC.sender?.wasFiltering = true
        }
    }
    
    @objc func prepareViews() {
        
        flowLayout.headerReferenceSize = .zero
        
        changeSize(to: infoBoldTextEnabled ? .regular : .light)
        headerHeight = topViewHeight
        
        headerView.scrollViews.forEach({ $0.contentOffset = .zero })
        
        prepareTopView()
        prepareAdded()
        preparePlayed()
        prepareSkips()
        prepareGenre()
        prepareSongOnlyViews()
        prepareCopyright()
        prepareCompilationAndExplicit()
        prepareDuration()
        prepareActionButtons()
        prepareRating()
        prepareUpdatedView()
        preparePlaylistButton() // for playlists I think
        preparePlayButtons()
        preparePlayShuffleButtons()
        
        var details: (song: MPMediaItem?, updateButton: Bool) {
            
            switch context {
                
                case .song(location: _, at: let index, within: let items): return (items[index], true)
                
                case .album(at: let index, within: let collections): return (query.collections?.first?.representativeItem ?? collections[index].representativeItem, false)
                
                case .collection(kind: _, at: let index, within: let collections): return (query.collections?.first?.representativeItem ?? collections[index].representativeItem, false)
                
                case .playlist(at: let index, within: let playlists): return (query.collections?.first?.representativeItem ?? playlists[index].representativeItem, false)
            }
        }
        
        var entities: Set<Entity> {
            
            switch context {
                
                case .song: return [.song, .album, .artist, .genre, .composer, .albumArtist]
                
                case .album: return [.album, .albumArtist, .genre]
                
                default: return [context.entity]
            }
        }
        
        entities.forEach({ verifyLibraryStatus(of: details.song, itemProperty: $0, updateButton: details.updateButton) })
        
        flowLayout.headerReferenceSize = .init(width: screenWidth, height: CGFloat(headerHeight))
        
        getPlaylists()
        
        firstLaunch = false
    }
    
    @IBAction func showLibraryOptions() {
        
        let vc = popoverStoryboard.instantiateViewController(withIdentifier: "actionsVC")
        vc.modalPresentationStyle = .popover
        
        guard let actionsVC = Transitioner.shared.transition(to: vc, using: .init(fromVC: self, configuration: .info, context: context), sourceView: actionsButton) else { return }
        
        show(actionsVC, sender: nil)
    }
    
    @objc func addToQueue() {
        
        Transitioner.shared.addToQueue(from: self, kind: .queries([query]), context: .other, index: (parent as? PresentedContainerViewController)?.index ?? -1, title: titleButton.title(for: .normal))
    }

    @IBAction func viewInContext() {
        
        switch context {
            
            case .song(location: _, at: let index, within: let items):
        
                guard isInDebugMode || (isInDebugMode.inverted && items[index] == musicPlayer.nowPlayingItem) else { return }
                
                let base = basePresentedOrNowPlayingViewController(from: parent)
                
                if !(base is NowPlayingViewController), let nowPlayingVC = container?.moveToNowPlaying(vc: nowPlayingStoryboard.instantiateViewController(withIdentifier: "nowPlaying"), showingQueue: false) as? NowPlayingViewController {
                    
                    if isInDebugMode {
                        
                        nowPlayingVC.alternateItem = items[index]
                    }
                    
                    base?.dismiss(animated: false, completion: { topViewController?.present(nowPlayingVC, animated: true, completion: nil) })
                
                } else {
                    
                    base?.dismiss(animated: true, completion: nil)
                }
            
            case .album: performUnwindSegue(with: .album, isEntityAvailable: albumQuery != nil, title: Entity.album.title())
            
            case .collection(kind: let kind, at: _, within: _):
            
                switch kind {
                    
                    case .artist: performUnwindSegue(with: .artist, isEntityAvailable: artistQuery != nil, title: Entity.artist.title(albumArtistOverride: false))
                    
                    case .composer: performUnwindSegue(with: .composer, isEntityAvailable: composerQuery != nil, title: Entity.composer.title())
                    
                    case .genre: performUnwindSegue(with: .genre, isEntityAvailable: genreQuery != nil, title: Entity.genre.title())
                    
                    case .albumArtist: performUnwindSegue(with: .albumArtist, isEntityAvailable: albumArtistQuery != nil, title: Entity.albumArtist.title(albumArtistOverride: false))
                }
            
            case .playlist(at: let index, within: let playlists):
            
                playlistQuery = MPMediaQuery.init(filterPredicates: [.for(.playlist, using: playlists[index])]).grouped(by: .playlist)
                performUnwindSegue(with: .playlist, isEntityAvailable: playlistQuery != nil, title: Entity.playlist.title())
        }
        
        noteFilterState()
    }
    
    @IBAction func alternateButton1Action() {
        
        switch context {
            
            case .song: performUnwindSegue(with: .artist, isEntityAvailable: artistQuery != nil, title: Entity.artist.title(albumArtistOverride: false))
            
            case .album: performUnwindSegue(with: albumArtistsAvailable ? .albumArtist : .artist, isEntityAvailable: albumArtistsAvailable ? albumArtistQuery != nil : artistQuery != nil, title: Entity.artist.title(albumArtistOverride: false))
            
            default: break
        }
    }
    
    @IBAction func alternateButton2Action() {
        
        switch context {
            
            case .song: performUnwindSegue(with: .album, isEntityAvailable: albumQuery != nil, title: Entity.album.title())
            
            default: break
        }
    }
    
    @IBAction func genreButtonAction() {
        
        switch context {
            
            case .song, .album: performUnwindSegue(with: .genre, isEntityAvailable: genreQuery != nil, title: Entity.genre.title())
            
            default: break
        }
    }
    
    @IBAction func composerButtonAction() {
        
        switch context {
            
            case .song: performUnwindSegue(with: .composer, isEntityAvailable: composerQuery != nil, title: Entity.composer.title())
            
            default: break
        }
    }
    
    @IBAction func albumArtistButtonAction() {
        
        switch context {
            
            case .song: performUnwindSegue(with: .albumArtist, isEntityAvailable: albumArtistQuery != nil, title: Entity.albumArtist.title())
            
            default: break
        }
    }
    
    @IBAction func play() {
        
        let details = songsDetails()

        musicPlayer.play(details.array, startingFrom: details.array.first, from: self, withTitle: details.title, alertTitle: "Play", completion: { self.parent?.performSegue(withIdentifier: "unwind", sender: nil) })
    }
    
    @IBAction func shuffle() {
        
        if case .song = context { return }
        
        let details = songsDetails()
        let canShuffleAlbums = details.array.canShuffleAlbums
        
        if canShuffleAlbums {
            
            var array = [UIAlertAction]()
            
            let shuffle = UIAlertAction.init(title: .shuffle(.songs), style: .default, handler: { _ in
                
                musicPlayer.play(details.array, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: details.title, alertTitle: .shuffle(.songs), completion: { self.parent?.performSegue(withIdentifier: "unwind", sender: nil) })
            })
            
            array.append(shuffle)
            
            let shuffleAlbums = UIAlertAction.init(title: .shuffle(.albums), style: .default, handler: { _ in
                
                musicPlayer.play(details.array.albumsShuffled, startingFrom: nil, from: self, withTitle: details.title, alertTitle: .shuffle(.albums), completion: { self.parent?.performSegue(withIdentifier: "unwind", sender: nil) })
            })
            
            array.append(shuffleAlbums)
            
            present(UIAlertController.withTitle(nil, message: titleButton.titleLabel?.text, style: .actionSheet, actions: array + [.cancel()]), animated: true, completion: nil)
            
        } else {
            
            musicPlayer.play(details.array, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: nil, alertTitle: .shuffle(), completion: { self.parent?.performSegue(withIdentifier: "unwind", sender: nil) })
        }
    }
    
    @IBAction func nextItem() {
        
        nextButton.isUserInteractionEnabled = false
        
        switch context {
            
            case .song(location: let location, at: let index, within: let array): context = .song(location: location, at: index + 1, within: array)
            
            case .album(at: let index, within: let array): context = .album(at: index + 1, within: array)
            
            case .collection(kind: let kind, at: let index, within: let array): context = .collection(kind: kind, at: index + 1, within: array)

            case .playlist(at: let index, within: let array): context = .playlist(at: index + 1, within: array)
        }
        
        query = getQuery()
        
        prepareViews()
        
        guard let presentedVC = parent as? PresentedContainerViewController, collectionView.contentOffset.y > 35 else { return }
        
        presentedVC.prompt = titleButton.title(for: .normal)
        presentedVC.updatePrompt(animated: false)
    }
    
    @IBAction func previousItem() {
        
        previousButton.isUserInteractionEnabled = false
        
        switch context {
            
            case .song(location: let location, at: let index, within: let array): context = .song(location: location, at: index - 1, within: array)
            
            case .album(at: let index, within: let array): context = .album(at: index - 1, within: array)
            
            case .collection(kind: let kind, at: let index, within: let array): context = .collection(kind: kind, at: index - 1, within: array)
            
            case .playlist(at: let index, within: let array): context = .playlist(at: index - 1, within: array)
        }
        
        query = getQuery()
        
        prepareViews()
        
        guard let presentedVC = parent as? PresentedContainerViewController, collectionView.contentOffset.y > 35 else { return }
        
        presentedVC.prompt = titleButton.title(for: .normal)
        presentedVC.updatePrompt(animated: false)
    }
    
    @objc func addSongs() {
        
        let picker = MPMediaPickerController.init(mediaTypes: .music)
        picker.allowsPickingMultipleItems = true
        picker.delegate = self
        picker.modalPresentationStyle = .overFullScreen
        
        present(picker, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let id = segue.identifier else { return }
        
        switch id {
            
            case .composerUnwind, .albumUnwind, .artistUnwind, .genreUnwind, .playlistUnwind, .albumArtistUnwind:
                
                noteFilterState()
                useAlternateAnimation = true
            
            default: break
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        switch context {
            
            case .song: return true
            
            case .album:
                
                if identifier == .genreUnwind {
                    
                    return genreQuery != nil
                }
            
                return false
            
            case .collection, .playlist: return false
        }
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        if !firstLaunch && showLyrics {
            
            collectionView.contentOffset = .init(x: 0, y: lyricsOffset)
            showLyrics = false
        }
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            let banner = UniversalMethods.banner(withTitle: "IVC going away...")
            banner.titleLabel.font = .myriadPro(ofWeight: .light, size: 22)
            banner.show(for: 0.3)
        }
    }
}

extension InfoViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return playlists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "playlistCell", for: indexPath) as! PlaylistCollectionViewCell
        
        let playlist = playlists[indexPath.row]
        
        let position: Position = {
            
            switch (indexPath.row + 1) % 3 {
                
                case 1: return .leading
                
                case 2: return .middle(single: false)
                
                default: return .trailing
            }
        }()
        
        cell.prepare(with: playlist, count: playlist.count, direction: .vertical, position: position, topConstraint: indexPath.row < 3 ? 4 : 2)
        cell.details = (.playlist, width)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        operations[indexPath]?.cancel()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let cell = cell as? PlaylistCollectionViewCell else { return }
        
        let playlist = playlists[indexPath.row]
        
        updateImageView(using: playlist, entityType: .playlist, in: cell, indexPath: indexPath, reusableView: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let playlist = playlists[indexPath.row]
        let query = MPMediaQuery.init(filterPredicates: [.for(.playlist, using: playlist)]).grouped(by: .playlist)
        
        playlistQuery = query
        collectionView.deselectItem(at: indexPath, animated: true)
        
        noteFilterState()
        
        performSegue(withIdentifier: .playlistUnwind, sender: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! InfoCollectionReusableView
        headerView = header
        
        return header
    }
}

extension InfoViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize.init(width: width, height: width + FontManager.shared.collectionViewCellConstant + 10 - 4 + (indexPath.row < 3 ? 4 : 2))
    }
}

extension InfoViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard let presentedVC = parent as? PresentedContainerViewController else { return }
        
        let offset: CGFloat = 35
        
        switch (scrollView.contentOffset.y, presentedVC.prompt) {
            
            case (let x, nil) where x > offset:
            
                presentedVC.prompt = titleButton.title(for: .normal)
                presentedVC.updatePrompt(animated: true)
            
            case (let x, let y) where x < offset + 1 && y != nil:
            
                presentedVC.prompt = nil
                presentedVC.updatePrompt(animated: true)
            
            default: break
        }
    }
}

extension InfoViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        if let superview = titleButton.superview, superview.bounds.contains(collectionView.convert(location, to: superview)) {
            
            if case .song = context { return nil }
            
            let sender: MPMediaItemCollection? = {
                
                switch context {
                
                    case .song: return nil
                    
                    case .playlist(at: let index, within: let playlists): return playlists[index]
                    
                    case .album(at: let index, within: let albums): return albums[index]
                    
                    case .collection(kind: _, at: let index, within: let collections): return collections[index]
                }
            }()
            
            let entityVC = entityStoryboard.instantiateViewController(withIdentifier: "entityItems")
            
            previewingContext.sourceRect = superview.convert(superview.bounds, to: collectionView)
            
            return Transitioner.shared.transition(to: context.entity, vc: entityVC, from: self, sender: sender, highlightedItem: currentItem, preview: true, titleOverride: (container?.activeViewController?.topViewController as? Navigatable)?.preferredTitle)
        
        } else if case .single = entityState, let superview = alternateButton1.superview, superview.bounds.contains(collectionView.convert(location, to: superview)), let details: (entity: Entity, collection: MPMediaItemCollection?) = {
            
            switch context {
                
                case .song: return (.artist, artistQuery?.collections?.first)
                
                case .album: return albumArtistsAvailable ? (.albumArtist, albumArtistQuery?.collections?.first) : (.artist, artistQuery?.collections?.first)
                
                default: return nil
            }
            
        }() {
            
            let entityVC = entityStoryboard.instantiateViewController(withIdentifier: "entityItems")
            
            previewingContext.sourceRect = superview.convert(superview.bounds, to: collectionView)
            
            return Transitioner.shared.transition(to: details.entity, vc: entityVC, from: self, sender: details.collection, highlightedItem: currentItem, preview: true, titleOverride: (container?.activeViewController?.topViewController as? Navigatable)?.preferredTitle)
        
        } else if case .song = context, case .single = entityState, let superview = alternateButton2.superview, superview.bounds.contains(collectionView.convert(location, to: superview)), let album = albumQuery?.collections?.first {
            
            let entityVC = entityStoryboard.instantiateViewController(withIdentifier: "entityItems")
            
            previewingContext.sourceRect = superview.convert(superview.bounds, to: collectionView)
            
            return Transitioner.shared.transition(to: .album, vc: entityVC, from: self, sender: album, highlightedItem: currentItem, preview: true, titleOverride: (container?.activeViewController?.topViewController as? Navigatable)?.preferredTitle)
        
        } else if case .single = entityState, let superview = genreButton.superview, superview.bounds.contains(collectionView.convert(location, to: superview)), let genre: MPMediaItemCollection = {
            
            switch context {
                
                case .song, .album: return genreQuery?.collections?.first
                
                default: return nil
            }
            
        }() {
            
            let entityVC = entityStoryboard.instantiateViewController(withIdentifier: "entityItems")
            
            previewingContext.sourceRect = superview.convert(superview.bounds, to: collectionView)
            
            return Transitioner.shared.transition(to: .genre, vc: entityVC, from: self, sender: genre, highlightedItem: currentItem, preview: true, titleOverride: (container?.activeViewController?.topViewController as? Navigatable)?.preferredTitle)
            
        } else if case .song = context, case .single = entityState, let superview = composerButton.superview, superview.bounds.contains(collectionView.convert(location, to: superview)), let composer = composerQuery?.collections?.first {
            
            let entityVC = entityStoryboard.instantiateViewController(withIdentifier: "entityItems")
            
            previewingContext.sourceRect = superview.convert(superview.bounds, to: collectionView)
            
            return Transitioner.shared.transition(to: .composer, vc: entityVC, from: self, sender: composer, highlightedItem: currentItem, preview: true, titleOverride: (container?.activeViewController?.topViewController as? Navigatable)?.preferredTitle)
        
        } else if case .song = context, case .single = entityState, let superview = albumArtistButton.superview, superview.bounds.contains(collectionView.convert(location, to: superview)) == true, let albumArtist = albumArtistQuery?.collections?.first {
            
            let entityVC = entityStoryboard.instantiateViewController(withIdentifier: "entityItems")
            
            previewingContext.sourceRect = superview.convert(superview.bounds, to: collectionView)
            
            return Transitioner.shared.transition(to: .albumArtist, vc: entityVC, from: self, sender: albumArtist, highlightedItem: currentItem, preview: true, titleOverride: (container?.activeViewController?.topViewController as? Navigatable)?.preferredTitle)
            
        } else if let indexPath = collectionView.indexPathForItem(at: location), let cell = collectionView.cellForItem(at: indexPath) as? PlaylistCollectionViewCell, let entityVC = entityStoryboard.instantiateViewController(withIdentifier: "entityItems") as? EntityItemsViewController {
            
            previewingContext.sourceRect = cell.artworkContainer.frame.convert(from: cell, to: collectionView) + cell.nameLabel.frame.convert(from: cell, to: collectionView) + cell.songCountLabel.frame.convert(from: cell, to: collectionView)//frame

            return Transitioner.shared.transition(to: .playlist, vc: entityVC, from: self, sender: playlists[indexPath.row], highlightedItem: currentItem, preview: true, titleOverride: (container?.activeViewController?.topViewController as? Navigatable)?.preferredTitle)
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        performCommitActions(on: viewControllerToCommit)
        
//        if let vc = viewControllerToCommit as? BackgroundHideable {
//
//            vc.modifyBackgroundView(forState: .removed)
//        }
//
//        if let vc = viewControllerToCommit as? Peekable {
//
//            vc.peeker = nil
//            vc.oldArtwork = nil
//        }
//
//        if let vc = viewControllerToCommit as? Navigatable, let indexer = vc.activeChildViewController as? IndexContaining {
//
//            indexer.tableView.contentInset.top = vc.inset
//            indexer.tableView.scrollIndicatorInsets.top = vc.inset
//
//            if let sortable = indexer as? FullySortable, sortable.highlightedIndex == nil {
//
//                indexer.tableView.contentOffset.y = -vc.inset
//            }
//
//            container?.imageView.image = vc.artworkType.image
//            container?.visualEffectNavigationBar.backBorderView.alpha = 1
//            container?.visualEffectNavigationBar.backView.isHidden = false
//            container?.visualEffectNavigationBar.backLabel.text = vc.backLabelText
//            container?.visualEffectNavigationBar.titleLabel.text = vc.title
//        }
        
        viewController = viewControllerToCommit
        
        noteFilterState()
        
        performSegue(withIdentifier: "preview", sender: nil)
    }
}

extension InfoViewController {
    
    func text(from number: Int, withOverride zeroOverride: String) -> String {
        
        guard number > 0 else { return zeroOverride }
        
        return String(number)
    }
    
    func prepareLyrics(with text: String) {
        
        let font = UIFont.font(ofWeight: infoBoldTextEnabled ? .regular : .light, size: 20)
        
        let size = (text as NSString).boundingRect(with: .init(width: screenWidth - 12 - 5 - 5, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil)
        
        lyricsTextView.text = text
        lyricsTextViewHeight = size.height + lyricsInset
        
        headerHeight += (lyricsLabelHeight + lyricsInset + size.height)
    }
    
    func prepareTopView() {
        
        guard let details: (currentItem: MPMediaItem?, entity: Entity, title: String?, alternateTitle1: String?, alternateTitle2: String?, alternateTitle3: String?, entityInstance: Any?) = {
            
            switch entityState {
                
                case .single:
                    
                    switch context {
                        
                        case .song(location: _, at: let index, within: let items):
                            
                            let item = items[index]
                        
                            return (item, .song, item.validTitle, item.validArtist, item.validAlbum, item.year == 0 ? nil : String(item.year), item)
                            
                        case .album(at: let index, within: let collections):
                            
                            let album = query.collections?.first ?? collections[index]
                        
                            guard let song = album.representativeItem else { return nil }
                            
                            return (song, .album, song.validAlbum, albumArtistsAvailable || song.isCompilation ? song.validAlbumArtist : song.validArtist, album.items.count.fullCountText(for: .song), album.year == 0 ? nil : String(album.year), album)
                            
                        case .collection(kind: let kind, at: let index, within: let collections):
                            
                            let collection = query.collections?.first ?? collections[index]
                        
                            guard let song = collection.representativeItem else { return nil }
                            
                            let albumCount = (query.copy() as? MPMediaQuery)?.grouped(by: .album).collections?.count ?? 0
                            let itemCount = (query.copy() as? MPMediaQuery)?.items?.count ?? 0
                            let artistCount = (query.copy() as? MPMediaQuery)?.grouped(by: .artist).collections?.count ?? 0
                            
                            switch kind {
                                
                                case .artist: return (song, .artist, song.validArtist, albumCount.fullCountText(for: .album), itemCount.fullCountText(for: .song), nil, collection)
                                
                                case .albumArtist: return (song, .albumArtist, song.validAlbumArtist, albumCount.fullCountText(for: .album), itemCount.fullCountText(for: .song), nil, collection)
                                
                                case .genre: return (song, .genre, song.validGenre, albumCount.fullCountText(for: .album), itemCount.fullCountText(for: .song), artistCount.fullCountText(for: .artist), collection)
                                
                                case .composer: return (song, .composer, song.validComposer, albumCount.fullCountText(for: .album), itemCount.fullCountText(for: .song), artistCount.fullCountText(for: .artist), collection)
                            }
                            
                        case .playlist(at: let index, within: let playlists):
                        
                            let playlist = query.collections?.first as? MPMediaPlaylist ?? playlists[index]
                            
                            let albumCount = (query.copy() as? MPMediaQuery)?.grouped(by: .album).collections?.count ?? 0
                            let itemCount =  (query.copy() as? MPMediaQuery)?.items?.count ?? 0
                            let artistCount = (query.copy() as? MPMediaQuery)?.grouped(by: .artist).collections?.count ?? 0
                            
                            return (playlist.items.first, .playlist, playlist.name ??? .untitledPlaylist, albumCount.fullCountText(for: .album), itemCount.fullCountText(for: .song), artistCount.fullCountText(for: .artist), playlist)
                    }
                    
                case .combined(previousIndex: _):
                    
                    switch context {
                        
                        case .song(location: _, at: _, within: let items):
                            
                            let titles = items.map({ $0.validTitle })
                            let artists = items.map({ $0.validArtist })
                            let albums = items.map({ $0.validAlbum })
                            let years = items.map({ $0.year }).filter({ $0 != 0 })
                            
                            return (nil, .song, titles.value(given: Set(titles).count < 2)?.first ?? "Mixed", artists.value(given: Set(artists).count < 2)?.first ?? "Mixed", albums.value(given: Set(albums).count < 2)?.first ?? "Mixed", years.value(given: Set(years).count == 1)?.first?.description ?? (years.isEmpty ? nil : "Mixed"), items.first)
                            
                        case .album(at: _, within: let collections):
                        
                            let albums = collections.compactMap({ $0.representativeItem?.validAlbum })
                            let artists = collections.compactMap({ $0.representativeItem?.validArtist })
                            let years = collections.map({ $0.year }).filter({ $0 != 0 })
                            let count = collections.reduce(0, { $0 + $1.count })
                        
                            return (nil, .album, albums.value(given: Set(albums).count < 2)?.first ?? "Mixed", artists.value(given: Set(artists).count < 2)?.first ?? "Mixed", count.countText(for: .song), years.value(given: Set(years).count == 1)?.first?.description ?? (years.isEmpty ? nil : "Mixed"), collections.first)
                        
                        case .collection(kind: let kind, at: _, within: let collections):
                        
                            let albumCount = queries.map({ $0.grouped(by: .album) }).reduce(0, { $0 + ($1.collections?.count ?? 0) })
                            let itemCount = collections.reduce(0, { $0 + $1.count })
                            let artistCount = queries.map({ $0.grouped(by: .artist) }).reduce(0, { $0 + ($1.collections?.count ?? 0) })
                            
                            switch kind {
                                
                                case .artist:
                                    
                                    let artists = collections.compactMap({ $0.representativeItem?.validArtist })
                                    
                                    return (nil, .artist, artists.value(given: Set(artists).count < 2)?.first ?? "Mixed", albumCount.fullCountText(for: .album), itemCount.fullCountText(for: .song), nil, collections.first)
                                    
                                case .genre:
                                    
                                    let genres = collections.compactMap({ $0.representativeItem?.validGenre })
                                    
                                    return (nil, .genre, genres.value(given: Set(genres).count < 2)?.first ?? "Mixed", albumCount.fullCountText(for: .album), itemCount.fullCountText(for: .song), artistCount.fullCountText(for: .artist), collections.first)
                                    
                                case .composer:
                                    
                                    let composers = collections.compactMap({ $0.representativeItem?.validComposer })
                                    
                                    return (nil, .composer, composers.value(given: Set(composers).count < 2)?.first ?? "Mixed", albumCount.fullCountText(for: .album), itemCount.fullCountText(for: .song), artistCount.fullCountText(for: .artist), collections.first)
                                
                                case .albumArtist:
                                
                                    let artists = collections.compactMap({ $0.representativeItem?.validAlbumArtist })
                                    
                                    return (nil, .artist, artists.value(given: Set(artists).count < 2)?.first ?? "Mixed", albumCount.fullCountText(for: .album), itemCount.fullCountText(for: .song), nil, collections.first)
                            }
                        
                        case .playlist(at: _, within: let playlists):
                        
                            let albumCount = queries.map({ $0.grouped(by: .album) }).reduce(0, { $0 + ($1.collections?.count ?? 0) })
                            let itemCount = playlists.reduce(0, { $0 + $1.count })
                            let artistCount = queries.map({ $0.grouped(by: .artist) }).reduce(0, { $0 + ($1.collections?.count ?? 0) })
                            
                            return (nil, .playlist, "Mixed", albumCount.fullCountText(for: .album), itemCount.fullCountText(for: .song), artistCount.fullCountText(for: .artist), playlists.first)
                    }
            }

        }() else { return }
        
        titleButton.isUserInteractionEnabled = {
            
            switch context {
                
                case .song(_, at: let index, within: let items): return isInDebugMode ? true : items[index] == musicPlayer.nowPlayingItem
                    
                default: return true
            }
        }()
        titleButton.setTitle(details.title, for: .normal)
        alternateButton1.setTitle(details.alternateTitle1, for: .normal)
        alternateButton2.setTitle(details.alternateTitle2, for: .normal)
        alternateButton3.setTitle(details.alternateTitle3, for: .normal)
        
        updateInfoArtwork(with: details.entityInstance)
    }
    
    func prepareAdded() {
        
        addedLabel.text = {
            
            headerHeight += infoHeight
            
            switch context {
                
                case .song(_, at: let index, within: let items):
                    
                    let song = items[index]
                    
                    guard song.existsInLibrary else { return "Not in Library" }
                    
                    return song.validDateAdded.timeIntervalSinceNow.shortStringRepresentation + " ago" + "  •  " + formatter.string(from: song.validDateAdded)
                    
                case .album(at: let index, within: let collections):
                    
                    let actualAlbum = query.collections?.first ?? collections[index]
                    
                    addedTitleLabel.text = "recently added"
                    
                    return actualAlbum.recentlyAdded.timeIntervalSinceNow.shortStringRepresentation + " ago" + "  •  " + formatter.string(from: actualAlbum.recentlyAdded)
                    
                case .collection(kind: _, at: let index, within: let collections):
                    
                    let actualCollection = query.collections?.first ?? collections[index]
                    
                    addedTitleLabel.text = "recently added"
                    
                    return actualCollection.recentlyAdded.timeIntervalSinceNow.shortStringRepresentation + " ago" + "  •  " + formatter.string(from: actualCollection.recentlyAdded)
                    
                case .playlist(let index, let playlists):
                    
                    let actualPlaylist = query.collections?.first as? MPMediaPlaylist ?? playlists[index]
                    
                    addedTitleLabel.text = "created"
                    
                    return actualPlaylist.dateCreated.timeIntervalSinceNow.shortStringRepresentation + " ago" + "  •  " + formatter.string(from: actualPlaylist.dateCreated)
            }
        }()
    }
    
    func preparePlayed() {
        
        playedLabel.text = {
            
            headerHeight += infoHeight
            
            switch context {
                
                case .song(location: _, let index, let items):
                    
                    let song = items[index]
                    
                    guard let date = song.lastPlayedDate else { return song.playCount.formatted }
                    
                    return song.playCount.formatted + " (Played \(date.timeIntervalSinceNow.shortStringRepresentation) ago  •  \(formatter.string(from: date)))"
                    
                case .album(let index, let collections):
                    
                    playsTitleLabel.text = "total plays"
                    
                    let actualAlbum = query.collections?.first ?? collections[index]
                    
                    return actualAlbum.totalPlays.formatted
                    
                case .collection(kind: _, let index, let collections):
                    
                    playsTitleLabel.text = "total plays"
                    
                    let actualCollection = query.collections?.first ?? collections[index]
                    
                    return actualCollection.totalPlays.formatted
                    
                case .playlist(let index, let playlists):
                    
                    playsTitleLabel.text = "total plays"
                    
                    let actualPlaylist = query.playlistsExtracted(showCloudItems: showiCloudItems).first ?? playlists[index]
                    
                    return actualPlaylist.totalPlays.formatted
            }
        }()
    }
    
    func prepareSkips() {
        
        skipsLabel.text = {
            
            headerHeight += infoHeight
            
            switch context {
                
                case .song(location: _, let index, let items):
                    
                    let song = items[index]
                    
                    guard let date = song.lastSkippedDate else { return song.skipCount.formatted }
                    
                    return song.skipCount.formatted + " (Skipped \(date.timeIntervalSinceNow.shortStringRepresentation) ago  •  \(formatter.string(from: date)))"
                
                case .album(let index, let collections):
                    
                    skipsTitleLabel.text = "total skips"
                    
                    let actualAlbum = query.collections?.first ?? collections[index]
                    
                    return actualAlbum.totalSkips.formatted
                
                case .collection(kind: _, let index, let collections):
                    
                    skipsTitleLabel.text = "total skips"
                    
                    let actualCollection = query.collections?.first ?? collections[index]
                    
                    return actualCollection.totalSkips.formatted
                
                case .playlist(let index, let playlists):
                    
                    skipsTitleLabel.text = "total skips"
                    
                    let actualPlaylist = query.playlistsExtracted(showCloudItems: showiCloudItems).first ?? playlists[index]
                    
                    return actualPlaylist.totalSkips.formatted
            }
        }()
    }
    
    func prepareGenre() {
        
        var genre: String? {
            
            switch context {
                
                case .song(location: _, let index, let items):
                    
                    let song = items[index]
                
                    guard song.genre?.isEmpty == false else { return nil }
                
                    return song.validGenre
                
                case .album(let index, let collections):
                
                    let actualCollection = query.collections?.first ?? collections[index]
                
                    return actualCollection.genre.disregarding(.untitledGenre)
                
                default: return nil
            }
        }
        
        genreButton.superview?.superview?.isHidden = {
            
            guard let genre = genre else { return true }
            
            headerHeight += infoHeight
            
            genreButton.setTitle(genre, for: .normal)
            otherEntities.append(.genre)
            
            return false
        }()
    }
    
    func prepareCopyright() {
        
        copyrightLabel.superview?.superview?.isHidden = {
            
            var text: String? {
                
                switch context {
                    
                    case .song(_, let index, let items): return items[index].copyright
                        
                    case .album(let index, let collections):
                        
                        let items = query.items ?? collections[index].items
                        
                        return items.first(where: { $0.copyright?.isEmpty == false })?.copyright
                    
                    default: return nil
                }
            }
            
            guard let copyright = text, !copyright.isEmpty else { return true }
            
            headerHeight += infoHeight
            
            copyrightLabel.text = copyright
            
            return false
        }()
    }
    
    func prepareDuration() {
        
        durationLabel.superview?.superview?.isHidden = {
            
            var details: (size: FileSize?, duration: TimeInterval) {
                
                switch context {
                    
                    case .song(location: _, at: let index, let items):
                        
                        let song = items[index]
                        
                        return (FileSize.init(actualSize: song.fileSize), song.playbackDuration)
                        
                    case .album(let index, let collections):
                        
                        let actualCollection = query.collections?.first ?? collections[index]
                        
                        return (FileSize.init(actualSize: actualCollection.totalSize), actualCollection.totalDuration)
                        
                    case .collection(kind: _, let index, let collections):
                    
                        let actualCollection = query.collections?.first ?? collections[index]
                        
                        return (FileSize.init(actualSize: actualCollection.totalSize), actualCollection.totalDuration)
                        
                    case .playlist(let index, let playlists):
                        
                        let actualCollection = query.playlistsExtracted(showCloudItems: showiCloudItems).first ?? playlists[index]
                        
                        guard !actualCollection.items.isEmpty else { return (nil, 0) }
                        
                        return (FileSize.init(actualSize: actualCollection.totalSize), actualCollection.totalDuration)
                }
            }
            
            guard let sizeDetails = details.size else { return true }
            
            headerHeight += infoHeight
            durationLabel.text = details.duration.stringRepresentation(as: .short) + " " + "(" + sizeDetails.actualSize.fileSizeRepresentation + ")"
            
            return false
        }()
    }
    
    func prepareRating() {
        
        entityRatingStackView.isHidden = {
            
            headerHeight += buttonsHeight
            
            if case .collection = context {
                
                headerView.rateShareView.canLikeEntity = false
            }
            
            headerView.rateShareView.entity = {
            
                switch context {
                    
                    case .song(location: _, at: let index, within: let items): return items[index]

                    case .album(at: let index, within: let collections): return collections[index]
                        
                    case .collection(kind: _, at: let index, within: let collections): return collections[index]
                        
                    case .playlist(at: let index, within: let playlists): return playlists[index]
                }
            }()
            
            return false
        }()
    }
    
    func prepareCompilationAndExplicit() {
        
        compilationButton.superview?.superview?.isHidden = {
            
            var details: (isCompilation: Bool, isExplicit: Bool) {
                
                switch context {
                    
                    case .song(location: _, let index, let items): return (items[index].isCompilation, items[index].isExplicit)
                    
                    case .album(let index, let collections): return (collections[index].representativeItem?.isCompilation == true, false)
                    
                    default: return (false, false)
                }
            }
            
            guard details.isCompilation || details.isExplicit else { return true }
            
            headerHeight += singleLineHeight
            
            compilationButton.superview?.isHidden = !details.isCompilation
            explicitButton.superview?.isHidden = !details.isExplicit
            
            return false
        }()
    }
    
    func preparePlaylistButton() {
        
        playlistsButton.superview?.isHidden = {
            
            headerHeight += singleLineHeight
            
            return false
        }()
    }
    
    func prepareActionButtons() {
        
        queueStackView.isHidden = {
            
            if case .playlist(let index, let playlists) = context {
                
                if (playlists[index].playlistAttributes != [] || playlists[index].isAppleMusic) && actionableSongs.isEmpty { return true }
            
            } else if actionableSongs.isEmpty { return true }
            
            headerHeight += buttonsHeight
            
            insertButton.superview?.isHidden = {
                
                if case .playlist(let index, let playlists) = context, playlists[index].playlistAttributes == [], !playlists[index].isAppleMusic {
                    
                    return false
                }
                
                return true
            }()
            
            queueButton.superview?.isHidden = {
                
                let shouldHide: Bool = {
                    
                    guard case .song(_, let index, let items) = context else { return false }
                    
                    return items[index] == musicPlayer.nowPlayingItem
                }()
                
                return actionableSongs.isEmpty || musicPlayer.nowPlayingItem == nil || shouldHide
            }()
            addToButton.superview?.isHidden = actionableSongs.isEmpty
            
            borderedButtons = []
            
            [headerView.queueView, headerView.addToView, headerView.insertView].forEach({
                
                if $0.isHidden == false {
                    
                    borderedButtons.append($0)
                }
            })
            
            updateButtons()
            
            return false
        }()
    }
    
    func prepareUpdatedView() {
        
        updatedLabel.superview?.superview?.isHidden = {
            
            guard case .playlist(at: let index, within: let playlists) = context, let date = playlists[index].dateUpdated else { return true }
            
            headerHeight += infoHeight
            
            updatedLabel.text = date.timeIntervalSinceNow.shortStringRepresentation + " ago" + "  •  " + formatter.string(from: date)
            
            return false
        }()
    }
    
    func prepareSongOnlyViews() {
        
        albumArtistButton.superview?.superview?.isHidden = {
            
            guard case .song(location: _, let index, let items) = context, items[index].albumArtist?.isEmpty == false else { return true }
            
            headerHeight += infoHeight
            
            albumArtistButton.setTitle(items[index].albumArtist, for: .normal)
            
            return false
        }()
        
        composerButton.superview?.superview?.isHidden = {
            
            guard case .song(location: _, let index, let items) = context, items[index].composer?.isEmpty == false else { return true }
            
            headerHeight += infoHeight
            
            composerButton.setTitle(items[index].composer, for: .normal)
            otherEntities.append(.composer)
            
            return false
        }()
        
        bpmLabel.superview?.superview?.isHidden = {
            
            guard case .song(location: _, let index, let items) = context else { return true }
            
            headerHeight += infoHeight
            
            bpmLabel.text = items[index].beatsPerMinute.formatted
            
            return false
        }()
        
        groupingLabel.superview?.superview?.isHidden = {
            
            guard case .song(location: _, let index, let items) = context, items[index].userGrouping?.isEmpty == false else { return true }
            
            headerHeight += infoHeight
            
            groupingLabel.text = items[index].userGrouping
            
            return false
        }()
        
        commentsLabel.superview?.superview?.isHidden = {
            
            guard case .song(location: _, let index, let items) = context, items[index].comments?.isEmpty == false else { return true }
            
            headerHeight += infoHeight
            
            commentsLabel.text = items[index].comments
            
            return false
        }()
        
        trackLabel.superview?.superview?.isHidden = {
            
            guard case .song(location: _, let index, let items) = context else { return true }
            
            let song = items[index]
            
            if song.albumTrackCount == 0, song.albumTrackNumber == 0, song.discCount == 0 { return true }
            
            headerHeight += infoHeight
            
            let trackText = song.albumTrackNumber > 0 || song.albumTrackCount > 0 ? "Track " + text(from: song.albumTrackNumber, withOverride: "#") + " of " + text(from: song.albumTrackCount, withOverride: "#") : ""
            
            let separator = (song.albumTrackNumber > 0 || song.albumTrackCount > 0) && song.discCount > 0 ? ", " : ""
            
            let discText = song.discCount > 0 ? "Disc " + text(from: song.discNumber, withOverride: "#") + " of " + text(from: song.discCount, withOverride: "#") : ""
            
            trackLabel.text = trackText + separator + discText
            
            return false
        }()
        
        lyricsTextView.superview?.isHidden = {
            
            guard case .song(location: _, let index, let items) = context, let lyrics = items[index].lyrics, !lyrics.isEmpty else { return true }
            
            lyricsOffset = CGFloat(headerHeight)
            
            lyricsTextView.textContainerInset = .init(top: 6, left: 5, bottom: 10, right: 5)
            
            prepareLyrics(with: lyrics)
            
            return false
        }()
    }
    
    func preparePlayButtons() {
        
        var details: (shouldHide: Bool, canMoveForward: Bool, canMoveBackward: Bool) {
            
            switch context {
                
                case .song(location: _, at: let index, within: let array):
                    
//                    var canMoveBackward: Bool {
//                        
//                        switch location {
//                            
//                            case .list: return index > 0
//                            
//                            case .queue(loaded: let loaded, index: let index):
//                            
//                                if let index = index {
//                                    
//                                    return
//                                }
//                        }
//                    }
                    
                    return (array.count < 2, index < array.endIndex - 1, index > 0)
                
                case .album(at: let index, within: let array): return (array.count < 2, index < array.endIndex - 1, index > 0)
                
                case .collection(kind: _, at: let index, within: let array): return (array.count < 2, index < array.endIndex - 1, index > 0)
                
                case .playlist(at: let index, within: let array): return (array.count < 2, index < array.endIndex - 1, index > 0)
            }
        }
        
        [previousButton, nextButton].forEach({ $0?.isHidden = details.shouldHide })
        previousButton.lightOverride = !details.canMoveBackward
        previousButton.isUserInteractionEnabled = details.canMoveBackward
        nextButton.lightOverride = !details.canMoveForward
        nextButton.isUserInteractionEnabled = details.canMoveForward
    }
    
    func preparePlayShuffleButtons() {
        
        var details: (lightOverride: Bool, shouldShowText: Bool, sideInsets: CGFloat, bottomInsets: CGFloat) {
            
            switch context {
                
                case .song(location: _, at: _, within: let array): return (true, array.count < 2, array.count > 1 ? 0 : 8, array.count > 1 ? 0 : 2)
                    
                case .album(at: let index, within: let array): return (array[index].items.count < 2, array.count < 2, array.count > 1 ? 0 : 8, array.count > 1 ? 0 : 2)
                    
                case .collection(kind: _, at: let index, within: let array): return (array[index].items.count < 2, array.count < 2, array.count > 1 ? 0 : 8, array.count > 1  ? 0 : 2)
                    
                case .playlist(at: let index, within: let array): return (array[index].items.count < 2, array.count < 2, array.count > 1 ? 0 : 8, array.count > 1 ? 0 : 2)
            }
        }
        
        shuffleButton.setTitle(details.shouldShowText ? .shuffle() : nil, for: .normal)
        shuffleButton.setImage(#imageLiteral(resourceName: "Shuffle13"), for: .normal)
        shuffleButton.isUserInteractionEnabled = !details.lightOverride
        shuffleButton.lightOverride = details.lightOverride
        playButton.setTitle(details.shouldShowText ? "Play" : nil, for: .normal)
        [playButton, shuffleButton].forEach({
        
            $0?.titleEdgeInsets.left = details.sideInsets
            $0?.imageEdgeInsets.right = details.sideInsets
            $0?.imageEdgeInsets.bottom = details.bottomInsets
        })
    }
    
    @objc func findInQueue() {
        
        if #available(iOS 10.3, *), !useSystemPlayer {
            
            
            
        } else {
            
            
        }
    }
    
    @objc func getPlaylists() {
        
        guard case .single = entityState else {
            
            playlistsActivityIndicator.stopAnimating()
            playlistsBorderView.isHidden = false
            
            playlistsButton.setTitle("no playlists"/*text*/, for: .normal)
            playlistsButton.greyOverride = true
            
            return
        }
        
        operation?.cancel()
        playlistsActivityIndicator.startAnimating()
        playlistsBorderView.isHidden = true
        
        operation = BlockOperation()
        operation?.addExecutionBlock({ [weak operation, weak self] in
            
            guard let weakSelf = self, let operation = operation else { return }
            
            var items: Set<MPMediaItem> {
                
                switch weakSelf.context {
                    
                    case .song(location: _, at: let index, within: let items): return Set([items[index]])
                    
                    case .album(at: let index, within: let collections): return Set(collections[index].items)
                    
                    case .collection(kind: _, at: let index, within: let collections): return Set(collections[index].items)
                    
                    case .playlist(at: let index, within: let playlists): return Set(playlists[index].items)
                }
            }
            
            let playlistsQuery: MPMediaQuery = MPMediaQuery.playlists().foldersAllowed(false).cloud
            
            var playlists = [MPMediaPlaylist]()
            var shouldCheck: Bool {
                
                if case .playlist(at: let index, within: let collections) = weakSelf.context, collections[index].items.count == 0 {
                    
                    return false
                }
                
                return true
            }
            
            if shouldCheck {
                
                for playlist in (playlistsQuery.collections as? [MPMediaPlaylist] ?? []) {
                    
                    if case .playlist(at: let index, within: let collections) = weakSelf.context, playlist.persistentID == collections[index].persistentID {
                        
                        continue
                    }
                    
                    if Set(playlist.items).intersection(items).count == items.count {
                        
                        if !showiCloudItems {
                            
                            let selString = NSString.init(format: "%@%@%@", "item", "sQu", "ery")
                            let sel = NSSelectorFromString(selString as String)
                            
                            if playlist.responds(to: sel), let query = playlist.value(forKey: "itemsQuery") as? MPMediaQuery {
                                
                                query.addFilterPredicate(.offline)
                            }
                        }
                        
                        playlists.append(playlist)
                    }
                }
            }
            
            OperationQueue.main.addOperation({
                
                guard !operation.isCancelled else { return }
                
                weakSelf.playlists = playlists.sorted(by: { ($0.name ??? .untitledPlaylist) < ($1.name ??? .untitledPlaylist) })
                
                weakSelf.playlistsActivityIndicator.stopAnimating()
                weakSelf.playlistsBorderView.isHidden = false
                
                weakSelf.playlistsButton.setTitle(playlists.count.fullCountText(for: .playlist), for: .normal)
                weakSelf.playlistsButton.greyOverride = weakSelf.playlists.isEmpty
                
                UIView.performWithoutAnimation { weakSelf.collectionView.layoutIfNeeded() }
                
                weakSelf.collectionView.reloadData()
            })
        })
        
        imageOperationQueue.addOperation(operation!)
    }
    
    func songsDetails() -> (array: [MPMediaItem], title: String) {
        
        switch context {
            
            case .song(location: _, let index, let items): return ([items[index]], items[index].title ??? .untitledSong)
            
            case .album(let index, let collections):
                
                let actualCollection = query.collections?.first ?? collections[index]
                
                return (actualCollection.items, actualCollection.representativeItem?.albumTitle ??? .untitledSong)
            
            case .collection(kind: let kind, let index, let collections):
                
                let actualCollection = query.collections?.first ?? collections[index]
            
                let title: String = {
                    
                    switch kind {
                        
                        case .artist: return actualCollection.representativeItem?.validArtist ??? .unknownArtist
                        
                        case .genre: return actualCollection.representativeItem?.validGenre ??? .untitledGenre
                        
                        case .composer: return actualCollection.representativeItem?.validComposer ??? .unknownComposer
                        
                        case .albumArtist: return actualCollection.representativeItem?.validAlbumArtist ??? .unknownArtist
                    }
                }()
            
                return (actualCollection.items, title)
            
            case .playlist(let index, let playlists):
                
                let actualCollection = query.collections?.first as? MPMediaPlaylist ?? playlists[index]
                
                return (actualCollection.items, actualCollection.name ??? .untitledPlaylist)
        }
    }
    
    func getQuery() -> MPMediaQuery {
        
        switch context {
            
            case .song(location: _, at: let index, within: let items):
                
                return .init(filterPredicates: [.for(.song, using: items[index])])
                
            case .album(at: let index, within: let collections): return MPMediaQuery.init(filterPredicates: [.for(.album, using: collections[index])]).cloud.grouped(by: .album)
                
            case .collection(kind: let kind, at: let index, within: let collections):
                
                let entity = kind.entity
                
                return MPMediaQuery.init(filterPredicates: [.for(entity, using: collections[index])]).cloud.grouped(by: entity.grouping)
                
            case .playlist(at: let index, within: let playlists): return MPMediaQuery.init(filterPredicates: [.for(.playlist, using: playlists[index])]).cloud.grouped(by: .playlist)
        }
    }
    
    func getQueries() -> [MPMediaQuery] {
        
        switch context {
            
            case .song(location: _, at: _, within: let items): return items.map({ MPMediaQuery.init(filterPredicates: [.for(.song, using: $0)]) })
            
            case .album(at: _, within: let collections): return collections.map({ MPMediaQuery.init(filterPredicates: [.for(.album, using: $0)]).cloud.grouped(by: .album) })
            
            case .collection(kind: let kind, at: _, within: let collections):
                
                let entity = kind.entity
                
                return collections.map({ MPMediaQuery.init(filterPredicates: [.for(entity, using: $0)]).cloud.grouped(by: entity.grouping) })
            
            case .playlist(at: _, within: let playlists): return playlists.map({ MPMediaQuery.init(filterPredicates: [.for(.playlist, using: $0)]).cloud.grouped(by: .playlist) })
        }
    }
}

extension InfoViewController: MPMediaPickerControllerDelegate {
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        guard case .playlist(let index, let playlists) = context, let playlist = MPMediaQuery.init(filterPredicates: [.for(.playlist, using: playlists[index])]).collections?.first as? MPMediaPlaylist else { return }
        
        (parent as? PresentedContainerViewController)?.activityIndicator.startAnimating()
        
        playlist.add(mediaItemCollection.items, completionHandler: { [weak self] error in
            
            guard let weakSelf = self else { return }
            
            guard error == nil else {
                
                UniversalMethods.performInMain {
                    
                    let banner = Banner.init(title: "Unable to add \(mediaItemCollection.items.count.fullCountText(for: .song))", subtitle: nil, image: nil, backgroundColor: .red, didTapBlock: nil)
                    banner.titleLabel.font = .myriadPro(ofWeight: .regular, size: 20)
                    banner.show(duration: 0.5)
                    
                    (weakSelf.parent as? PresentedContainerViewController)?.activityIndicator.stopAnimating()
                }
                
                return
            }
            
            UniversalMethods.performInMain {
                
                let banner = Banner.init(title: "\(playlist.name ??? "Untitled Playlist")", subtitle: "Added \(mediaItemCollection.items.count.fullCountText(for: .song))", image: nil, backgroundColor: .deepGreen, didTapBlock: nil)
                banner.titleLabel.font = .myriadPro(ofWeight: .light, size: 25)
                banner.detailLabel.font = .myriadPro(ofWeight: .light, size: 20)
                banner.detailLabel.textColor = Themer.textColour(for: .subtitle)
                banner.show(for: .bannerInterval)
                
                notifier.post(name: .songsAddedToPlaylists, object: nil, userInfo: [String.addedPlaylists: [playlist.persistentID], String.addedSongs: mediaItemCollection.items])
                weakSelf.parent?.performSegue(withIdentifier: "unwind", sender: nil)
            }
        })
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        
        mediaPicker.dismiss(animated: true, completion: nil)
    }
}

extension InfoViewController: UIGestureRecognizerDelegate {
    
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//
//        return otherGestureRecognizer is UILongPressGestureRecognizer
//    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return gestureRecognizer.location(in: view).x > 44
    }
}

extension InfoViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        
        indexPaths.forEach({
            
            guard let cell = collectionView.cellForItem(at: $0) as? PlaylistCollectionViewCell else { return }
            
            updateImageView(using: playlists[$0.row], entityType: .playlist, in: cell, indexPath: $0, reusableView: collectionView)
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        
        indexPaths.forEach({ operations[$0]?.cancel() })
    }
}

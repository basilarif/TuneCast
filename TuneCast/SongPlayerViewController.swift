//
//  SongPlayerViewController.swift
//  TuneCast
//
//  Created by Kenneth Galang on 2019-11-23.
//  Copyright © 2019 CARFAX Ca. All rights reserved.
//

import UIKit
import StoreKit

class SongPlayerViewController: UIViewController, SPTAppRemotePlayerStateDelegate,
                                SPTAppRemoteUserAPIDelegate,
                                SpeedPickerViewControllerDelegate,
                                SKStoreProductViewControllerDelegate {
    
    
    private let playURI = ""
    private let trackIdentifier = ""
    private let trackIdentifierInQueue = "spotify:album:5uMfshtC2Jwqui0NUyUYIL"
    private let name = "Now Playing View"
    
    private var currentPodcastSpeed: SPTAppRemotePodcastPlaybackSpeed?
    
    // MARK: - Lifecycle
    
    @IBAction func pressedPlay(_ sender: Any) {
        print(AppDelegate.accessToken)
        playTrack()
//        if let wtf = AppDelegate.accessToken{
//            print("WTF?: ", wtf)
//            AppDelegate.accessToken = wtf
//        }
        print("PlayMe")
        appRemote.authorizeAndPlayURI(playURI)
    }
    private var connectionIndicatorView = ConnectionStatusIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Here")
    }
    
    
    
    
    
        // MARK: - View
        
        @IBOutlet weak var trackNameLabel: UILabel!
        @IBOutlet var buttons: [UIButton]!
        
        @IBOutlet var nextButton: UIButton!
        @IBOutlet var prevButton: UIButton!

        @IBOutlet var skipForward15Button: UIButton!
        @IBOutlet var skipBackward15Button: UIButton!
        @IBOutlet var podcastSpeedButton: UIButton!
        
        private func updateViewWithPlayerState(_ playerState: SPTAppRemotePlayerState) {
            updatePlayPauseButtonState(playerState.isPaused)
            updateRepeatModeLabel(playerState.playbackOptions.repeatMode)
            updateShuffleLabel(playerState.playbackOptions.isShuffling)
            trackNameLabel.text = playerState.track.name + " - " + playerState.track.artist.name
            fetchAlbumArtForTrack(playerState.track) { (image) -> Void in
                self.updateAlbumArtWithImage(image)
            }
            updateViewWithRestrictions(playerState.playbackRestrictions)
            updateInterfaceForPodcast(playerState: playerState)
        }

        private func updateViewWithRestrictions(_ restrictions: SPTAppRemotePlaybackRestrictions) {
            nextButton.isEnabled = restrictions.canSkipNext
            prevButton.isEnabled = restrictions.canSkipPrevious
            toggleShuffleButton.isEnabled = restrictions.canToggleShuffle
            toggleRepeatModeButton.isEnabled = restrictions.canRepeatContext || restrictions.canRepeatTrack
        }

        private func encodeStringAsUrlParameter(_ value: String) -> String {
            let escapedString = value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            return escapedString!
        }

        private func enableInterface(_ enabled: Bool = true) {
            buttons.forEach { (button) -> () in
                button.isEnabled = enabled
            }

            if (!enabled) {
                albumArtImageView.image = nil
                updatePlayPauseButtonState(true);
            }
        }

        // MARK: Podcast Support

        private func updateInterfaceForPodcast(playerState: SPTAppRemotePlayerState) {
            skipForward15Button.isHidden = !playerState.track.isEpisode
            skipBackward15Button.isHidden = !playerState.track.isEpisode
            podcastSpeedButton.isHidden = !playerState.track.isPodcast
            nextButton.isHidden = !skipForward15Button.isHidden
            prevButton.isHidden = !skipBackward15Button.isHidden
            getCurrentPodcastSpeed()
        }

        private func updatePodcastSpeed(speed: SPTAppRemotePodcastPlaybackSpeed) {
            currentPodcastSpeed = speed
            podcastSpeedButton.setTitle(String(format: "%0.1fx", speed.value.floatValue), for: .normal);
        }
    
        // MARK: Player Control

        @IBOutlet weak var playPauseButton: UIButton!

        @IBAction func didPressPlayPauseButton(_ sender: AnyObject) {
            if !(appRemote.isConnected) {
                if (!appRemote.authorizeAndPlayURI(playURI)) {
                    // The Spotify app is not installed, present the user with an App Store page
                    showAppStoreInstall()
                }
            } else if playerState == nil || playerState!.isPaused {
                startPlayback()
            } else {
                pausePlayback()
            }
        }

        @IBAction func didPressPreviousButton(_ sender: AnyObject) {
            skipPrevious()
        }

        @IBAction func didPressNextButton(_ sender: AnyObject) {
            skipNext()
        }

        @IBAction func didPressPlayTrackButton(_ sender: AnyObject) {
            playTrack()
        }

        @IBAction func didPressSkipForward15Button(_ sender: UIButton) {
            seekForward15Seconds()
        }

        @IBAction func didPressSkipBackward15Button(_ sender: UIButton) {
            seekBackward15Seconds()
        }

        @IBAction func didPressChangePodcastPlaybackSpeedButton(_ sender: UIButton) {
            pickPodcastSpeed()
        }

        @IBAction func didPressEnqueueTrackButton(_ sender: AnyObject) {
            enqueueTrack()
        }

        private func updatePlayPauseButtonState(_ paused: Bool) {
            let playPauseButtonImage = paused ? PlaybackButtonGraphics.playButtonImage() : PlaybackButtonGraphics.pauseButtonImage()
            playPauseButton.setImage(playPauseButtonImage, for: UIControl.State())
            playPauseButton.setImage(playPauseButtonImage, for: .highlighted)
        }

        // MARK: Player State

        @IBOutlet weak var playerStateSubscriptionButton: UIButton!

        @IBAction func didPressGetPlayerStateButton(_ sender: AnyObject) {
            getPlayerState()
        }

        @IBAction func didPressPlayerStateSubscriptionButton(_ sender: AnyObject) {
            if (subscribedToPlayerState) {
                unsubscribeFromPlayerState()
            } else {
                subscribeToPlayerState()
            }
        }
        
        private func updatePlayerStateSubscriptionButtonState() {
            let playerStateSubscriptionButtonTitle = subscribedToPlayerState ? "Unsubscribe" : "Subscribe"
            playerStateSubscriptionButton.setTitle(playerStateSubscriptionButtonTitle, for: UIControl.State())
        }

        // MARK: Capabilities

        @IBOutlet weak var onDemandCapabilitiesLabel: UILabel!
        @IBOutlet weak var capabilitiesSubscriptionButton: UIButton!

        @IBAction func didPressGetCapabilitiesButton(_ sender: AnyObject) {
            fetchUserCapabilities()
        }

        @IBAction func didPressCapabilitiesSubscriptionButton(_ sender: AnyObject) {
            if (subscribedToCapabilities) {
                unsubscribeFromCapailityChanges()
            } else {
                subscribeToCapabilityChanges()
            }
        }

        private func updateViewWithCapabilities(_ capabilities: SPTAppRemoteUserCapabilities) {
            onDemandCapabilitiesLabel.text = "Can play on demand: " + (capabilities.canPlayOnDemand ? "Yes" : "No")
        }

        private func updateCapabilitiesSubscriptionButtonState() {
            let capabilitiesSubscriptionButtonTitle = subscribedToCapabilities ? "Unsubscribe" : "Subscribe"
            capabilitiesSubscriptionButton.setTitle(capabilitiesSubscriptionButtonTitle, for: UIControl.State())
        }

        // MARK: Shuffle Button

        @IBOutlet weak var toggleShuffleButton: UIButton!
        @IBOutlet weak var shuffleModeLabel: UILabel!

        @IBAction func didPressToggleShuffleButton(_ sender: AnyObject) {
            toggleShuffle()
        }
        private func updateShuffleLabel(_ isShuffling: Bool) {
            shuffleModeLabel.text = "Shuffle mode: " + (isShuffling ? "On" : "Off")
        }

        // MARK: Repeat Mode Button

        @IBOutlet weak var toggleRepeatModeButton: UIButton!
        @IBOutlet weak var repeatModeLabel: UILabel!
        @IBAction func didPressToggleRepeatModeButton(_ sender: AnyObject) {
            toggleRepeatMode()
        }

        private func updateRepeatModeLabel(_ repeatMode: SPTAppRemotePlaybackOptionsRepeatMode) {
            repeatModeLabel.text = "Repeat mode: " + {
                switch repeatMode {
                case .off: return "Off"
                case .track: return "Track"
                case .context: return "Context"
                default: return "Off"
                }
                }()
        }

        // MARK: Album Art

        @IBOutlet weak var albumArtImageView: UIImageView!

        private func updateAlbumArtWithImage(_ image: UIImage) {
            self.albumArtImageView.image = image
            let transition = CATransition()
            transition.duration = 0.3
            transition.type = CATransitionType.fade
            self.albumArtImageView.layer.add(transition, forKey: "transition")
        }
        
        

        private var playerState: SPTAppRemotePlayerState?
        private var subscribedToPlayerState: Bool = false
        
        
        var defaultCallback: SPTAppRemoteCallback {
            get {
                return {[weak self] _, error in
                    if let error = error {
                        self?.displayError(error as NSError)
                    }
                }
            }
        }
        
        private func displayError(_ error: NSError?) {
            if let error = error {
                presentAlert(title: "Error", message: error.description)
            }
        }

        private func presentAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

        // MARK: StoreKit

        private func showAppStoreInstall() {
            if TARGET_OS_SIMULATOR != 0 {
                presentAlert(title: "Simulator In Use", message: "The App Store is not available in the iOS simulator, please test this feature on a physical device.")
            } else {
                let loadingView = UIActivityIndicatorView(frame: view.bounds)
                view.addSubview(loadingView)
                loadingView.startAnimating()
                loadingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
                let storeProductViewController = SKStoreProductViewController()
                storeProductViewController.delegate = self
                storeProductViewController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: SPTAppRemote.spotifyItunesItemIdentifier()], completionBlock: { (success, error) in
                    loadingView.removeFromSuperview()
                    if let error = error {
                        self.presentAlert(
                            title: "Error accessing App Store",
                            message: error.localizedDescription)
                    } else {
                        self.present(storeProductViewController, animated: true, completion: nil)
                    }
                })
            }
        }

        public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
            viewController.dismiss(animated: true, completion: nil)
        }
        
        var appRemote: SPTAppRemote {
            get {
                return AppDelegate.sharedInstance.appRemote
            }
        }
        
        private func seekForward15Seconds() {
            appRemote.playerAPI?.seekForward15Seconds(defaultCallback)
        }

        private func seekBackward15Seconds() {
            appRemote.playerAPI?.seekBackward15Seconds(defaultCallback)
        }

        private func pickPodcastSpeed() {
            appRemote.playerAPI?.getAvailablePodcastPlaybackSpeeds({ (speeds, error) in
                if error == nil, let speeds = speeds as? [SPTAppRemotePodcastPlaybackSpeed], let current = self.currentPodcastSpeed {
                    let vc = SpeedPickerViewController(podcastSpeeds: speeds, selectedSpeed: current)
                    vc.delegate = self
                    let nav = UINavigationController(rootViewController: vc)
                    self.present(nav, animated: true, completion: nil)
                }
            })
        }
        
        private func skipNext() {
            appRemote.playerAPI?.skip(toNext: defaultCallback)
        }

        private func skipPrevious() {
            appRemote.playerAPI?.skip(toPrevious: defaultCallback)
        }

        private func startPlayback() {
            appRemote.playerAPI?.resume(defaultCallback)
        }

        private func pausePlayback() {
            appRemote.playerAPI?.pause(defaultCallback)
        }
        
        private func playTrack() {
            print("Am Play Track")
            appRemote.playerAPI?.play(trackIdentifier, callback: defaultCallback)
        }
        
        private func enqueueTrack() {
            appRemote.playerAPI?.enqueueTrackUri(trackIdentifierInQueue, callback: defaultCallback)
    //        appRemote.playerAPI?.enqueueTrackUri(trackIdentifier, callback: defaultCallback)
        }

        private func toggleShuffle() {
            guard let playerState = playerState else { return }
            appRemote.playerAPI?.setShuffle(!playerState.playbackOptions.isShuffling, callback: defaultCallback)
        }

        private func getPlayerState() {
            appRemote.playerAPI?.getPlayerState { (result, error) -> Void in
                guard error == nil else { return }

                let playerState = result as! SPTAppRemotePlayerState
                self.updateViewWithPlayerState(playerState)
            }
        }
        
        private func getCurrentPodcastSpeed() {
            appRemote.playerAPI?.getCurrentPodcastPlaybackSpeed({ (speed, error) in
                guard error == nil, let speed = speed as? SPTAppRemotePodcastPlaybackSpeed else { return }
                self.updatePodcastSpeed(speed: speed)
            })
        }

        private func playTrackWithIdentifier(_ identifier: String) {
            appRemote.playerAPI?.play(identifier, callback: defaultCallback)
        }

        private func subscribeToPlayerState() {
            guard (!subscribedToPlayerState) else { return }
            appRemote.playerAPI!.delegate = self
            appRemote.playerAPI?.subscribe { (_, error) -> Void in
                guard error == nil else { return }
                self.subscribedToPlayerState = true
                self.updatePlayerStateSubscriptionButtonState()
            }
        }
        
        private func unsubscribeFromPlayerState() {
            guard (subscribedToPlayerState) else { return }
            appRemote.playerAPI?.unsubscribe { (_, error) -> Void in
                guard error == nil else { return }
                self.subscribedToPlayerState = false
                self.updatePlayerStateSubscriptionButtonState()
            }
        }

        private func toggleRepeatMode() {
            guard let playerState = playerState else { return }
            let repeatMode: SPTAppRemotePlaybackOptionsRepeatMode = {
                switch playerState.playbackOptions.repeatMode {
                case .off: return .track
                case .track: return .context
                case .context: return .off
                default: return .off
                }
            }()

            appRemote.playerAPI?.setRepeatMode(repeatMode, callback: defaultCallback)
        }

        // MARK: - Image API

        private func fetchAlbumArtForTrack(_ track: SPTAppRemoteTrack, callback: @escaping (UIImage) -> Void ) {
            appRemote.imageAPI?.fetchImage(forItem: track, with:CGSize(width: 1000, height: 1000), callback: { (image, error) -> Void in
                guard error == nil else { return }

                let image = image as! UIImage
                callback(image)
            })
        }

        // MARK: - User API
        private var subscribedToCapabilities: Bool = false

        private func fetchUserCapabilities() {
            appRemote.userAPI?.fetchCapabilities(callback: { (capabilities, error) in
                guard error == nil else { return }

                let capabilities = capabilities as! SPTAppRemoteUserCapabilities
                self.updateViewWithCapabilities(capabilities)
            })
        }

        private func subscribeToCapabilityChanges() {
            guard (!subscribedToCapabilities) else { return }
            appRemote.userAPI!.delegate = self
            appRemote.userAPI?.subscribe(toCapabilityChanges: { (success, error) in
                guard error == nil else { return }

                self.subscribedToCapabilities = true
                self.updateCapabilitiesSubscriptionButtonState()
            })
        }

        private func unsubscribeFromCapailityChanges() {
            guard (subscribedToCapabilities) else { return }
            AppDelegate.sharedInstance.appRemote.userAPI?.unsubscribe(toCapabilityChanges: { (success, error) in
                guard error == nil else { return }

                self.subscribedToCapabilities = false
                self.updateCapabilitiesSubscriptionButtonState()
            })
        }

        // MARK: - <SPTAppRemotePlayerStateDelegate>

        func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
            self.playerState = playerState
            updateViewWithPlayerState(playerState)
        }

        // MARK: - <SPTAppRemoteUserAPIDelegate>

        func userAPI(_ userAPI: SPTAppRemoteUserAPI, didReceive capabilities: SPTAppRemoteUserCapabilities) {
            updateViewWithCapabilities(capabilities)
        }

        func showError(_ errorDescription: String) {
            let alert = UIAlertController(title: "Error!", message: errorDescription, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        func appRemoteConnecting() {
            connectionIndicatorView.state = .connecting
        }

        func appRemoteConnected() {
            connectionIndicatorView.state = .connected
            subscribeToPlayerState()
            subscribeToCapabilityChanges()
            getPlayerState()

            enableInterface(true)
        }

        func appRemoteDisconnect() {
            connectionIndicatorView.state = .disconnected
            self.subscribedToPlayerState = false
            self.subscribedToCapabilities = false
            enableInterface(false)
        }

        // MARK: - SpeedPickerViewController

        func speedPickerDidCancel(viewController: SpeedPickerViewController) {
            viewController.dismiss(animated: true, completion: nil)
        }

        func speedPicker(viewController: SpeedPickerViewController, didChoose speed: SPTAppRemotePodcastPlaybackSpeed) {
            appRemote.playerAPI?.setPodcastPlaybackSpeed(speed, callback: { (_, error) in
                guard error == nil else {
                    return
                }
                self.updatePodcastSpeed(speed: speed)
            })
            viewController.dismiss(animated: true, completion: nil)
        }
}


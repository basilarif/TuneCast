//
//  getSongsViewController.swift
//  TuneCast
//
//  Created by CARFAX Ca on 2019-11-24.
//  Copyright © 2019 CARFAX Ca. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import Alamofire
import Spartan

struct songElement:Codable {
    var songName : String!
    var artistName : String!
    var trackId : String!
    var likes : Int!
    var username  : String!
    var email : String!
    var timestamp : String!
}

var search = ""


class songQueueTableCell: UITableViewCell {
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var userName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}

class getSongsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var searchArtist: UITextField!
    
    @IBAction func textInput(_ sender: UITextField) {
        search = searchArtist.text!
    }
    let cellSpacingHeight: CGFloat = 5
    
    func numberOfSections(in tableView: UITableView) -> Int {
     
            return 1
    
          
       }
       
       func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
           return cellSpacingHeight
       }
       
       func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int){
           view.tintColor = .clear
           let header = view as! UITableViewHeaderFooterView
           header.textLabel?.textColor = UIColor.white
       }
       
       func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           return self.songs.count
       }
    
    var songs = [songElement]()
    var isDone = false
    func getSongs(hostEmail: String){
        let db = Firestore.firestore()
        let ref = db.collection("hosts").whereField("email", isEqualTo: hostEmail)
        ref.getDocuments() {
            (querySnapshot, error) in
            if let error = error {
                print("Error getting host documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    let hostRef = document.reference
                    let songQueue = hostRef.collection("songQueue").order(by: "likes", descending: true)
                    songQueue.getDocuments() {
                        (querySnapshotSongs, error) in
                        if let error = error {
                            print("Error getting song documents: \(error)")
                        } else {
                            print("found this many songs", querySnapshotSongs!.documents.count)
                            for song in querySnapshotSongs!.documents {
                                let songName = song.data()["songName"] as! String
                                let artistName = song.data()["artistName"] as! String
                                let trackId = song.data()["trackID"] as! String
                                let likes = song.data()["likes"] as! Int
                                let username = song.data()["username"] as! String
                                let email = song.data()["email"] as! String
                                let time = song.data()["timestamp"] as! String
                                self.songs.append(songElement(songName: songName, artistName: artistName, trackId: trackId, likes: likes, username: username, email: email, timestamp: time))
                                self.isDone = true
                                self.tableView.reloadData()
                            }
                        }
                    }
                   
                }
            }
        }
    }
    override func viewDidLoad() {
        search = searchArtist.text!
        let hostEmail = myAccount.hostEmail
        if hostEmail != ""{
            getSongs(hostEmail: hostEmail)
        }
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        let hostEmail = myAccount.hostEmail
        if hostEmail != ""{
            //getSongs(hostEmail: hostEmail){
        }
    }
    
    @objc func dismissKeyboard() {
               //Causes the view (or one of its embedded text fields) to resign the first responder status.
               view.endEditing(true)
           }
           @objc func keyboardWillShow(notification: NSNotification) {
               if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                   if self.view.frame.origin.y == 0 {
                       self.view.frame.origin.y -= keyboardSize.height/2
                   }
               }
           }
           
           @objc func keyboardWillHide(notification: NSNotification) {
               if self.view.frame.origin.y != 0 {
                   self.view.frame.origin.y = 0
               }
           }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
               let cell = tableView.dequeueReusableCell(withIdentifier: "songCell", for:indexPath) as! songQueueTableCell
                if isDone == true {
                    //print(self.songs[indexPath.section].songName)
                    cell.songName.text = songs[indexPath.row].songName
                    cell.userName.text = "by " + songs[indexPath.row].username
                    cell.artistName.text = songs[indexPath.row].artistName
                }
               cell.layer.borderColor = UIColor.black.cgColor
               return cell
           }
    
    func appendSongToPlaylist(userID: String, playlistID: String, trackUris: [String]){
           _ = Spartan.addTracksToPlaylist(userId: userID, playlistId: playlistID, trackUris: trackUris, success: { (snapshot) in
               // Do something with the snapshot
           }, failure: { (error) in
               print(error)
           })
       }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSong = songs[indexPath.row]
        let playId = myAccount.playlistID
        var playID = playId as! String
        var tracks = [String]()
        tracks.append(selectedSong.trackId)
        appendSongToPlaylist(userID: "zynebbx", playlistID: playID, trackUris: tracks)
       }
    
}

struct Song {
    var id: String
    var name: String
    var mainImage: UIImage!
    var artist: String
    init(id: String, name: String, mainImage: UIImage, artist: String){
        self.id = id
        self.name = name
        self.mainImage = mainImage
        self.artist = artist
    }
}

class TableViewController: UITableViewController {
    var songs = [Song]()
    
    
//    var headers = ["Authorization": "Bearer \(AppDelegate.accessToken)" ]
    var headers = ["Authorization": " Bearer BQDjtObts1WT-1_ZDlXRGp6f0tuIC96iSmvynjuBR5k9u7DfoWFAysfkBFK1kDMdRf9_fgTiem1za0KHqgdaxE45B9oxs9MgE4UPa0ubItQCzW1EvZTXEm9nMHWTFaqhkV4D-IasRJ3AyMfO_TZk95_yAO2gDqwENqeSED__MTWbzAVh_Yj9-EGXDbSO8ey6sgvpeeM9oqnWWFaLE_vx7rmI_sSAPZTGhO2aux4wcT3po70rNiIW0r9ZfM3v2D3o2C0-rX6OHw"]
//    var searchURL = ""
//    let artist = search
    let searchURL = "https://api.spotify.com/v1/search?q=\(search)&type=track&limit=10&offset=5"
    typealias JSONStandard = [String: AnyObject]
    override func viewDidLoad() {
        super.viewDidLoad()
//        headers = ["Authorization": "Bearer \(AppDelegate.accessToken)" ]
        print(headers)
        print("Lol")
        print(search)
        
//        let searchURL = "https://api.spotify.com/v1/search?q=" + artist + "&type=track%2Cartist&market=US&limit=10&offset=5"
        print(searchURL)
        // Do any additional setup after loading the view.
        callAlamo(url: searchURL)
    }
    
    func callAlamo(url: String){
//        AF.request(url, method: .get, headers: headers).responseJSON(completionHandler: {
        
        Alamofire.request(searchURL, method: .get, headers: headers).responseJSON(completionHandler: {
            response in
            self.parseData(response.data!)
            
        })
    }
    
    func parseData(_ JSONData: Data){
        do{
            
            var readableJSON = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as! JSONStandard
            if let tracks = readableJSON["tracks"] as? JSONStandard{
                if let items = tracks["items"] as? [[String : Any]]{
                    for song in items{
                        let name = song["name"]
                        let id = song["id"]
                        
//                        names.append(name as! String)
//                        idList.append(id as! String)
                        if let album = song["album"] as? JSONStandard{
                            if let images = album["images"] as? [JSONStandard]{
                                let imageData = images[0]
                                let mainImageURL = URL(string: imageData["url"] as! String)
                                let mainImageData = NSData(contentsOf: mainImageURL!)
                                if let artist = album["name"]{
                                    let mainImage = UIImage(data: mainImageData as! Data)
                                    songs.append(Song(id: id as! String, name: name as! String, mainImage: mainImage!, artist: artist as! String))
                                    print(Song(id: id as! String, name: name as! String, mainImage: mainImage!, artist: artist as! String))
                                    print("ok man", Song(id: id as! String, name: name as! String, mainImage: mainImage!, artist: artist as! String))
                                }
                                
                            }
                            
                        }
                        
                    }
                    tableView.reloadData()
                }
                
            }
//            print(songs)
            print(readableJSON)
        }
        catch{
            print(error)
        }
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        cell?.textLabel?.text = songs[indexPath.row].name
        cell?.imageView?.image = songs[indexPath.row].mainImage
        print("SONGS", songs)
//        let mainImageView = cell?.viewWithTag(3) as! UIImageView
//        mainImageView.image = songs[indexPath.row].mainImage
//        let mainLabel = cell?.viewWithTag(2) as! UILabel
//        mainLabel.text = songs[indexPath.row].name
        return cell!
    }
    func addSongToQueueHelper(song: songElement, completion: @escaping (_ message: String) -> Void){
        let db = Firestore.firestore()
        let hostRef = db.collection("hosts").whereField("email", isEqualTo: myAccount.hostEmail)
        hostRef.getDocuments() {
            (querySnapshot, error) in
            if let error = error {
                print("Error getting host documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    let host = document.reference
                    self.addSongToQueue(ref: host, song: song)
                    completion("success")
                }
            }
        }
    }
    func addSongToQueue(ref: DocumentReference?, song: songElement){
        let docData : [String:Any] = [
            "songName"    : song.songName!,
            "artistName"  : song.artistName!,
            "trackID"     : song.trackId!,
            "likes"       : song.likes!,
            "username"    : song.username!,
            "email"       : song.email!,
            "timestamp"   : song.timestamp!
        ]
        _ = ref!.collection("songQueue").addDocument(data: docData){ err in
            if let err = err{
                print("error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }
   func appendSongToPlaylist(userID: String, playlistID: String, trackUris: [String]){
           _ = Spartan.addTracksToPlaylist(userId: userID, playlistId: playlistID, trackUris: trackUris, success: { (snapshot) in
               // Do something with the snapshot
           }, failure: { (error) in
               print(error)
           })
       }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let trackId = songs[indexPath.row].id
        let artist = songs[indexPath.row].artist
        let name = songs[indexPath.row].name
        
        let newSongElement = songElement(songName: name, artistName: artist, trackId: trackId, likes: 0, username: myAccount.UserName, email: myAccount.email, timestamp: "test")
        addSongToQueueHelper(song: newSongElement){ (success) in
            if success == "success"{
                let selectedSong = newSongElement
                let playId = myAccount.playlistID
                var playID = playId as! String
                var tracks = [String]()
                tracks.append(selectedSong.trackId)
                self.appendSongToPlaylist(userID: "zynebbx", playlistID: myAccount.playlistID, trackUris: tracks)
                print("added to firebase")
                self.performSegue(withIdentifier: "goBackToViewController", sender: self)
            }
        }
        print(songs[indexPath.row].id)
    }
    
    
    
}




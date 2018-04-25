
import UIKit

class FriendsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, AddFriendDelegate {
    
    @IBOutlet weak var tv: UITableView!
    
    var friendObjects: [Friend] = []
    
    var friends:  [BackendlessUser] = []
    var friendId: [String] = []
    
    let searchController = UISearchController(searchResultsController: nil)
    var filteredFriends: [BackendlessUser] = []
    
    let dataStore = backendless!.data.of(Friend.ofClass())
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadFriends()
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tv.tableHeaderView = searchController.searchBar
    }
    
    // MARK: IBActions
    
    @IBAction func addFriendsBarButton_Pressed (_ sender: AnyObject) {
        performSegue(withIdentifier: "friendToAddFriend-Segue", sender: self)
    }
    
    // MARK: Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredFriends.count
        }
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "Cell") as! FriendCell
        var friend: BackendlessUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            friend = filteredFriends[indexPath.row]
        } else {
            friend = friends[indexPath.row]
        }
        cell.bindData(friend: friend)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true // so we can delete our friends
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        // delete friend
    }
    
    // MARK: Table view delegate functions
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tv.deselectRow(at: indexPath, animated: true)
        var friend: BackendlessUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            friend = filteredFriends[indexPath.row]
            
        } else {
            friend = friends[indexPath.row]
        }
        
        // create a chat
    }
    
    func loadFriends() {
        
        cleanup()
        
        let whereClause = "userOneId = '\(backendless!.userService.currentUser.objectId!)'"
        print(backendless!.userService.currentUser.objectId)
        let dataQuery = DataQueryBuilder()
        dataQuery!.setWhereClause(whereClause)
        
        dataStore?.find(dataQuery, response: { (friends_) -> () in
            
            if friends_ != nil {
                
                print("USER HAS FRIENDS")
                let friends = friends_! as! [Friend]
                self.friendObjects = friends
                
                for friend in friends {
                    
                    //      self.friends.append(friend.userTwo!)
                    //     self.friendId.append(friend.userTwo!.objectId as String) // get user's id
                    self.friendId.append(friend.userTwo as! String) // get user's id
                    
                }
                
                self.fetchFriends(withIds: self.friendId)
                
                self.tv.reloadData()
                
                if self.friends.count == 0 {
                    
                    ProgressHUD.show("Currently there are no added friends", interaction: false)
                }
            }
            
        }) { (fault) in
            
            print("Couldn't load friends. Error: \(fault!.detail)")
            
        }
    }
    
    //new function
    func fetchFriends(withIds: [String]) {
        
        let string = "'" + withIds.joined(separator: "', '") + "'"
        let whereClause = "objectId IN (\(string))"
        let queryBuilder = DataQueryBuilder()
        queryBuilder!.setWhereClause(whereClause)
        
        let dataStore = backendless!.persistenceService.of(BackendlessUser.ofClass())
        dataStore?.find(queryBuilder, response: {
            (allUsers) -> () in
            
            if allUsers != nil {
                
                for friendUser in allUsers as! [BackendlessUser] {
                    self.friends.append(friendUser)
                }
                self.tv.reloadData()
            }
            
        }, error: {
            (fault : Fault?) -> () in
            print("Couldnt load all friends: \(fault!.detail)")
        })
    }
    
    // MARK: Helper functions
    
    func cleanup() {
        
        friendObjects.removeAll()
        friends.removeAll()
        friendId.removeAll()
        tv.reloadData()
    }
    
    // MARK: Search controller
    
    func filteredContentForSearchText(searchText: String, scope: String = "All") {
        
        filteredFriends = friends.filter { friend in
            
            return friend.name.lowercased.contains(searchText.lowercased())
        }
        
        tv.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        filteredContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    
    // MARK: AddFriend delegate function
    
    func saveFriend(selectedFriend: BackendlessUser) {
        
        if friendId.contains(selectedFriend.objectId as String) {
            return
        }
        
        let friend = Friend()
        friend.userOneId = backendless!.userService.currentUser.objectId as String
        friend.userTwo = selectedFriend.objectId! as String
        
        
        dataStore!.save(friend, response: { (result) in
            
            print("SAVED FRIEND")
            
            self.loadFriends()
            
        }) { (fault) in
            
            ProgressHUD.showError("Error saving friend - \(fault!.detail)")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "friendToAddFriend-Segue" {
            
            let vc = segue.destination as! AddFriendVC
            vc.delegate = self
            
            vc.hidesBottomBarWhenPushed = true
        }
    }
}

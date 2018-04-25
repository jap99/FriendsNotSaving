
import UIKit

protocol AddFriendDelegate {
    
    func saveFriend(selectedFriend: BackendlessUser)
}


class AddFriendVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {
    
    @IBOutlet weak var tv: UITableView!
    
    var users: [BackendlessUser] = []
    
    let searchController = UISearchController(searchResultsController: nil)
    var filteredUsers: [BackendlessUser] = []  
    
    var delegate: AddFriendDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadUsers()
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tv.tableHeaderView = searchController.searchBar
        
    }
    
    
    // MARK: Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            
            return filteredUsers.count
        } else {
            
            return users.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tv.dequeueReusableCell(withIdentifier: "Cell") as! FriendCell
        
        var user: BackendlessUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            
            user = filteredUsers[indexPath.row]
        } else {
            
            user = users[indexPath.row]
        }
        
        cell.bindData(friend: user)
        
        return cell
    }
    
    
    // MARK: Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let user: BackendlessUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            
            user = filteredUsers[indexPath.row]
        } else {
            
            user = users[indexPath.row]
        }
        
        delegate.saveFriend(selectedFriend: user)
        
        tv.deselectRow(at: indexPath, animated: true)
        self.navigationController!.popViewController(animated: true)
    }
    
    
    
    // MARK: Load Users
    
    func loadUsers() {
        
        let whereClause = "objectId != '\(backendless!.userService.currentUser.objectId!)'"
        
        let dataQuery = DataQueryBuilder()
        dataQuery!.setWhereClause(whereClause)
        
        let dataStore = backendless!.persistenceService.of(BackendlessUser.ofClass())
        
        dataStore!.find(dataQuery, response: { (users) in
            print("PRINTING USERS - \(users)")
            //self.users = users!.data as! [BackendlessUser]
            self.users = users! as! [BackendlessUser]
            self.tv.reloadData()
            
        }) { fault in
            
            ProgressHUD.showError("Couldn't load users: \(fault!.detail)")
        }
    }
    
    
    // MARK: Search controller
    
    func filteredContentForSearchText(searchText: String, scope: String = "All") {
        
        filteredUsers = users.filter { user in
            
            return user.name.lowercased.contains(searchText.lowercased())
        }
        
        tv.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        filteredContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    
    
    
    
    
    
    
    
}

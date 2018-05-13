
import UIKit

class FavoritesController: UITableViewController, AsyncEventType {
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Offline"
        
        self.subscribeOnEvents { (call: Call<ConnectionStatus> ) -> Void in
            
            switch call {
                
            case .onSuccess(.CONNECTED):
                self.navigationItem.title = "Online"
                break
                
            case .onError( _):
                self.navigationItem.title = "Offline"
                break
                
            default: break
                
            }
        }
        
        let logingService = LoginService()
        
        logingService.login()

    }
    
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 0
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        
        return cell
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        
    }
    
}

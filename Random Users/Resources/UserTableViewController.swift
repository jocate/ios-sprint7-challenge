//
//  UserTableViewController.swift
//  Random Users
//
//  Created by Jocelyn Stuart on 2/22/19.
//  Copyright © 2019 Erica Sadun. All rights reserved.
//

import UIKit

class UserTableViewController: UITableViewController {

    let userController = UserController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userController.getUsers(completion: { (error) in
            if let error = error {
                print(error)
            }
            self.tableView.reloadData()
        })
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return userController.users.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserTableViewCell

        let user = userController.users[indexPath.row]
        
        loadImage(forCell: cell, forItemAt: indexPath)
        
        cell.nameLabel.text = user.name

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let photo = userController.users[indexPath.row]
        
        if let operation = fetchOperations[photo.name] {
            operation.cancel()
        }
    }
    
    var fetchOperations: [String: FetchPhotoOperation] = [:]

    private func loadImage(forCell cell: UserTableViewCell, forItemAt indexPath: IndexPath) {
        
        // TODO: Implement image loading here
        
        let photoReference = userController.users[indexPath.row]
       // let photoURL = URL(string: photoReference.thumbnail)!
        
        if let cacheImage = cache.valueSmall(for: photoReference.name){
            
            cell.imageThumbnail.image = UIImage(data: cacheImage)
            
        } else {
            
            let fetchPhotoOp = FetchPhotoOperation(user: photoReference)
            
            fetchOperations[photoReference.name] = fetchPhotoOp
            
            let storeDataOp = BlockOperation {
                self.cache.cacheSmall(value: fetchPhotoOp.imageData!, for: photoReference.name)
            }
            
            let reuseOp = BlockOperation {
                guard let currentIndex = self.tableView.indexPath(for: cell) else { return }
                
                
                if currentIndex == indexPath {
                    
                    cell.imageThumbnail.image = UIImage(data: fetchPhotoOp.imageData!)
                    
                } else {
                    return
                }
            }
            
            storeDataOp.addDependency(fetchPhotoOp)
            reuseOp.addDependency(fetchPhotoOp)
            
            photoFetchQueue.addOperation(fetchPhotoOp)
            photoFetchQueue.addOperation(storeDataOp)
            OperationQueue.main.addOperation(reuseOp)
            
            
          /*
             let dataTask = URLSession.shared.dataTask(with: photoURL) { (photoData, _, error) in
             
                if let error = error {
                    print("Error: \(error)")
                    return
                }
             
                guard let photoData = photoData else { return }
             
                let photo = UIImage(data: photoData)
             
                self.cache.cacheSmall(value: photoData, for: photoReference.name)
             
                DispatchQueue.main.async {
                    guard let currentIndex = self.tableView.indexPath(for: cell) else { return }
             
                    if currentIndex == indexPath {
             
                        cell.imageThumbnail.image = photo
             
                    } else {
                        return
                    }
                }
            }
            dataTask.resume()*/
        }
        
    }
    
    // Properties..
    
    let photoFetchQueue = OperationQueue()
    let cache = Cache<String, Data>()

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UserDetail" {
            guard let cellDetailController = segue.destination as? UserDetailViewController, let cell = sender as? UserTableViewCell else { return }
            
            cellDetailController.userController = userController
            cellDetailController.user = cell.user
            
        }
    }
    
}

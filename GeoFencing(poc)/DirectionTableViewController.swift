//
//  DirectionTableViewController.swift
//  GeoFencing(poc)
//
//  Created by Admin on 26/12/22.
//

import UIKit

class DirectionTableViewController: UITableViewController {
    
    var directions = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

       
    }

    // MARK: - Table view data source

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        return directions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DirectionCell", for: indexPath)
        cell.textLabel?.text = directions[indexPath.row]
        return cell
    }
   

}

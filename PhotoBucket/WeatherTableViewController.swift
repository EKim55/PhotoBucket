//
//  WeatherTableViewController.swift
//  PhotoBucket
//
//  Created by CSSE Department on 4/17/18.
//  Copyright © 2018 CSSE Department. All rights reserved.
//

import UIKit
import CoreData

class WeatherTableViewController: UITableViewController {

    var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let weatherCellIdentifier = "WeatherCell"
    let noWeatherCellIdentifier = "NoWeatherCell"
    let showDetailSegueIdentifier = "ShowDetailSegue"
    var weatherArray = [Weather]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem:
            UIBarButtonSystemItem.add,  target: self, action: #selector(showAddDialog))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateWeatherArray()
        tableView.reloadData()
    }
    
    @objc func showAddDialog() {
        let alertController = UIAlertController(title: "Create a new photo",
                                                message: "",
                                                preferredStyle: .alert)
        alertController.addTextField{ (textField) in
            textField.placeholder = "Caption"
        }
        alertController.addTextField{ (textField) in
            textField.placeholder = "Image URL or blank"
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: UIAlertActionStyle.cancel,
                                         handler: nil)
        let createWeatherAction = UIAlertAction(title: "Create",
                                              style: UIAlertActionStyle.default) {
                                                (action) in
                                                let captionTextField = alertController.textFields![0]
                                                let urlTextField = alertController.textFields![1]
                                                if urlTextField.text == "" {
                                                    urlTextField.text = self.getRandomImageUrl()
                                                }
                                                print("captionTextField = \(captionTextField)")
                                                print("urlTextField = \(urlTextField)")
                                                let newWeather = Weather(context: self.context)
                                                newWeather.caption = captionTextField.text!
                                                newWeather.imageURL = urlTextField.text!
                                                newWeather.created = Date()
                                                self.save()
                                                self.updateWeatherArray()
                                                if (self.weatherArray.count == 1) {
                                                    self.tableView.reloadData()
                                                }
                                                else {
                                                    self.tableView.insertRows(at: [IndexPath(row:0, section: 0)],
                                                                              with: UITableViewRowAnimation.top)
                                                }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(createWeatherAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func getRandomImageUrl() -> String {
        let testImages = ["https://upload.wikimedia.org/wikipedia/commons/0/04/Hurricane_Isabel_from_ISS.jpg",
                          "https://upload.wikimedia.org/wikipedia/commons/0/00/Flood102405.JPG",
                          "https://upload.wikimedia.org/wikipedia/commons/6/6b/Mount_Carmel_forest_fire14.jpg"]
        let randomIndex = Int(arc4random_uniform(UInt32(testImages.count)))
        return testImages[randomIndex];
    }

    func save() {
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    func updateWeatherArray() {
        // Make a fetch request
        // Execute the request in a try/catch block
        let request: NSFetchRequest<Weather> = Weather.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "created", ascending: false)];
        do {
            weatherArray = try context.fetch(request)
        } catch {
            fatalError("Unresolved Core Data error \(error)")
        }
    }
    
    // MARK: - Table view data source
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        if weatherArray.count == 0 {
            super.setEditing(false, animated: animated)
        } else {
            super.setEditing(editing, animated: animated)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(weatherArray.count, 1)
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        if weatherArray.count == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: noWeatherCellIdentifier, for: indexPath)
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: weatherCellIdentifier, for: indexPath)
            cell.textLabel?.text = weatherArray[indexPath.row].caption
            
        }
        
        // Configure the cell...
        return cell
    }
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return weatherArray.count != 0
    }
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            context.delete(weatherArray[indexPath.row])
            save()
            updateWeatherArray()
            // Delete the row from the data source
            if weatherArray.count == 0 {
                tableView.reloadData()
                self.setEditing(false, animated: true)
            } else {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == showDetailSegueIdentifier) {
            if let indexPath = tableView.indexPathForSelectedRow {
                (segue.destination as! WeatherDetailViewController).weather = weatherArray[indexPath.row]
            }
        }
    }
}

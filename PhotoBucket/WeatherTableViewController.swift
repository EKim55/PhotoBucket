//
//  WeatherTableViewController.swift
//  PhotoBucket
//
//  Created by CSSE Department on 4/17/18.
//  Copyright © 2018 CSSE Department. All rights reserved.
//

import UIKit
import Firebase

class WeatherTableViewController: UITableViewController {

    var weatherRef: CollectionReference!
    var weatherListener: ListenerRegistration!
    
    let weatherCellIdentifier = "WeatherCell"
    let noWeatherCellIdentifier = "NoWeatherCell"
    let showDetailSegueIdentifier = "ShowDetailSegue"
    var weatherArray = [Weather]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem:
            UIBarButtonSystemItem.add,  target: self, action: #selector(showAddDialog))
        weatherRef = Firestore.firestore().collection("weather")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.weatherArray.removeAll()
        weatherListener = weatherRef.order(by: "created", descending: true).limit(to: 50).addSnapshotListener({ (querySnapshot, error) in
            guard let snapshot = querySnapshot else {
                print("Error fetching weather. error: \(error!.localizedDescription)")
                return
            }
            snapshot.documentChanges.forEach({ (docChange) in
                if (docChange.type == .added) {
                    print("New weather: \(docChange.document.data())")
                    self.weatherAdded(docChange.document)
                } else if (docChange.type == .modified) {
                    print("Modified weather: \(docChange.document.data())")
                    self.weatherUpdate(docChange.document)
                } else if (docChange.type == .removed) {
                    print("Removed weather: \(docChange.document.data())")
                    self.weatherRemoved(docChange.document)
                }
                self.navigationItem.title = docChange.document.get("title") as? String
                self.weatherArray.sort(by: { (w1, w2) -> Bool in
                    return w1.created > w2.created
                })
                self.tableView.reloadData()
            })
        })
    }
    
    func weatherAdded(_ document: DocumentSnapshot) {
        let newWeather = Weather(documentSnapshot: document)
        weatherArray.append(newWeather)
    }
    
    func weatherUpdate(_ document: DocumentSnapshot) {
        let modifiedWeather = Weather(documentSnapshot: document)
        for weather in weatherArray {
            if (weather.id == modifiedWeather.id) {
                weather.caption = modifiedWeather.caption
                weather.imageURL = modifiedWeather.imageURL
                break
            }
        }
    }
    
    func weatherRemoved(_ document: DocumentSnapshot) {
        let removedWeather = Weather(documentSnapshot: document)
        for i in 0..<weatherArray.count {
            if (weatherArray[i].id == removedWeather.id) {
                weatherArray.remove(at: i)
                break
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        weatherListener.remove()
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
                                                let newWeather = Weather(caption: captionTextField.text!, imageURL: urlTextField.text!)
                                                self.weatherRef.addDocument(data: newWeather.data)
                                                
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
            let weatherToDelete = weatherArray[indexPath.row]
            weatherRef.document(weatherToDelete.id!).delete()
        }
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == showDetailSegueIdentifier) {
            if let indexPath = tableView.indexPathForSelectedRow {
                (segue.destination as! WeatherDetailViewController).weatherRef = weatherRef.document(weatherArray[indexPath.row].id!)
            }
        }
    }
}

//
//  WeatherDetailViewController.swift
//  PhotoBucket
//
//  Created by CSSE Department on 4/17/18.
//  Copyright © 2018 CSSE Department. All rights reserved.
//

import UIKit
import Firebase

class WeatherDetailViewController: UIViewController {

    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var weatherRef: DocumentReference?
    var weatherListener: ListenerRegistration!
    var weather: Weather?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(showEditDialog))
        self.spinner.startAnimating()
    }

    @objc func showEditDialog() {
        let alertController = UIAlertController(title: "Edit weather",
                                                message: "",
                                                preferredStyle: .alert)
        alertController.addTextField{ (textField) in
            textField.placeholder = "Caption"
            textField.text = self.weather?.caption
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: UIAlertActionStyle.cancel,
                                         handler: nil)
        let createWeatherAction = UIAlertAction(title: "Edit",
                                              style: UIAlertActionStyle.default) {
                                                (action) in
                                                let captionTextField = alertController.textFields![0]
                                                print("captionTextField = \(captionTextField)")
                                                self.weather?.caption = captionTextField.text!
                                                self.weatherRef?.setData(self.weather!.data)
                                                
        }
        alertController.addAction(cancelAction)
        alertController.addAction(createWeatherAction)
        present(alertController, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        weatherListener = weatherRef?.addSnapshotListener({ (documentSnapshot, error) in
            if let error = error {
                print("Error getting the document: \(error.localizedDescription)")
                return
            }
            if !documentSnapshot!.exists {
                print("This document got deleted by someone else.")
                return
            }
            self.weather = Weather(documentSnapshot: documentSnapshot!)
            self.updateView()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        weatherListener.remove()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let imgString = weather?.imageURL {
            if let imgURL = URL(string: imgString) {
                DispatchQueue.global().async {
                    do {
                        let data = try Data(contentsOf: imgURL)
                        DispatchQueue.main.async {
                            self.imageView.image = UIImage(data: data)
                        }
                    } catch {
                        print("Error downloading image: \(error)")
                    }
                }
            }
        }
    }
    
    func updateView() {
        captionLabel.text = weather?.caption
    }

}

//
//  ViewController.swift
//  TextSomeone
//
//  Created by Aditya Bansod on 1/7/15.
//  Copyright (c) 2015 Aditya Bansod. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var whenToAlert: UISegmentedControl!
    @IBOutlet weak var location: UITextField!
    @IBOutlet weak var message: UITextField!
    @IBOutlet weak var phone: UITextField!
    @IBOutlet weak var enabled: UISwitch!
    @IBOutlet weak var street: UITextField!
    
    var locationManager:CLLocationManager?
    var region:CLCircularRegion?
    let regionIdentifier = "AlertRegion"
    
    let geocodingUrl = "https://maps.googleapis.com/maps/api/geocode/json?key=YOURKEYHERE&latlng="
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestAlwaysAuthorization()
        
        if let regions = locationManager?.monitoredRegions {
            if regions.count > 0 {
                // TODO this for loop doesn't really make sense
                // since there should only ever be one region monitored
                for region in regions {
                    let thisregion = region as? CLCircularRegion
                    self.region = thisregion
                    self.location.text = formatCoordinate(thisregion!.center)
                    self.enabled.on = true
                }
            }
        }
        loadStoredValues()

    }
    
    func loadStoredValues() {
        let storedValues: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let message = storedValues.valueForKey("message") as? String {
            self.message.text = message
        }
        if let phone = storedValues.valueForKey("phone") as? String {
            self.phone.text = phone
        }
        reverseGeocodeLatLon(self.region!.center)
    }
    
    func reverseGeocodeLatLon(coord: CLLocationCoordinate2D) {
        let string = self.geocodingUrl + "\(coord.latitude),\(coord.longitude)"
        let url = NSURL(string: string)
        
        var jsonError: NSError?
        
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            if let results = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError) as? NSDictionary {
                let streetname = ((results.valueForKey("results") as NSArray)[0] as NSDictionary)["formatted_address"] as NSString
                self.street.text = streetname
                
            }
        }
        task.resume()
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func locationButton(sender: UIButton) {
        locationManager?.startUpdatingLocation()
    }
    
    @IBAction func enabledButton(sender: UISwitch) {
        if message.text == "" {
            createAlert("Set a message", message: "Please fill in the message before enabling")
            stopRegionMonitoring()
            sender.on = false
        }
        
        if phone.text == "" {
            createAlert("Set a phone number", message: "Please set a phone number before enabling")
            stopRegionMonitoring()
            sender.on = false
        }
        
        if let setRegion = self.region  {
            if sender.on {
                startRegionMonitoring()
            } else {
                stopRegionMonitoring()
            }
        } else {
            stopRegionMonitoring()
            createAlert("Set a location", message: "Push the arrow button to set a location to start monitoring")
            sender.on = false
        }
    }
    
    func startRegionMonitoring() {
        if let setRegion = self.region {
            NSLog("starting to monitor \(region)")
            locationManager?.startMonitoringForRegion(region)
            let storedValues: NSUserDefaults = NSUserDefaults.standardUserDefaults()
            storedValues.setValue(message.text, forKey: "message")
            storedValues.setValue(phone.text, forKey: "phone")
            storedValues.synchronize()
        }
    }
    
    func stopRegionMonitoring() {
        if let setRegion = self.region {
            NSLog("ending monitoring on \(region)")
            locationManager?.stopMonitoringForRegion(region)
            // TODO since we're not persisting the region anywhere between app launches
            // just to be safe, destroy all regions being monitored
            if let regions = locationManager?.monitoredRegions {
                for region in regions {
                    locationManager?.stopMonitoringForRegion(region as CLRegion)
                }
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        NSLog("failed with error \(error)")
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let coordinate = (locations.last as CLLocation).coordinate
        self.location.text = formatCoordinate(coordinate)
        reverseGeocodeLatLon(coordinate)

        locationManager?.stopUpdatingLocation()
        
        let region = CLCircularRegion(center: coordinate, radius: 50, identifier: self.regionIdentifier)
        NSLog("set region as \(region)")
        self.region = region
    }
    
    func locationManager(manager: CLLocationManager!, didStartMonitoringForRegion region: CLRegion!) {
        NSLog("monitoring begun for \(region)")
        generateNotification("Monitoring", message: "Monitoring \(region.identifier)", userInfo: nil)
    }
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        if enabled.on {
            loadStoredValues()
            var userInfo = [String:String]()
            userInfo["phone"] = self.phone.text
            userInfo["message"]  = self.message.text
            
            generateNotification("Entered", message: "Entered \(region.identifier)", userInfo: userInfo)
            NSLog("entering \(region.identifier)")
            
        }
    }
    
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        if enabled.on {
            loadStoredValues()
            var userInfo = [String:String]()
            userInfo["phone"] = self.phone.text
            userInfo["message"]  = self.message.text

            generateNotification("Exited", message: "Exited \(region.identifier)", userInfo: userInfo)
            NSLog("exiting \(region.identifier)")
        }
    }
    
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let destroyAction = UIAlertAction(title: "Dismiss", style: .Default) { (action) in
            return
        }
        alert.addAction(destroyAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func generateNotification(title: String, message: String, userInfo:[String:String]?) {
        let localNotification:UILocalNotification = UILocalNotification()
        localNotification.alertAction = title
        localNotification.alertBody = message
        localNotification.fireDate = NSDate(timeIntervalSinceNow: 10)
        localNotification.userInfo = userInfo
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    func formatCoordinate(cord: CLLocationCoordinate2D) -> String {
        return "\(cord.latitude), \(cord.longitude)"
    }

}


import UIKit

/**
 Layer App ID from developer.layer.com
 */
let LQSLayerAppIDString = "LAYER_APP_ID"

#if arch(i386) || arch(x86_64) // Simulator
    
// If on simulator set the user ID to Simulator and participant to Device
let LQSCurrentUserID = "Simulator"
let LQSParticipantUserID = "Device"
let LQSInitialMessageText = "Hey Device! This is your friend, Simulator."
    
#else // Device

// If on device set the user ID to Device and participant to Simulator
let LQSCurrentUserID = "Device"
let LQSParticipantUserID = "Simulator"
let LQSInitialMessageText = "Hey Simulator! This is your friend, Device."
    
#endif

let LQSParticipant2UserID = "Dashboard"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, LYRClientDelegate {

    var window: UIWindow?
    var layerClient: LYRClient!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Check if Sample App is using a valid app ID.
        if (isValidAppID()) {
            // Add support for shake gesture
            application.applicationSupportsShakeToEdit = true
            
            // Show a usage the first time the app is launched
            showFirstTimeMessage()

            // Initializes a LYRClient object
            let appID = NSUUID(UUIDString: LQSLayerAppIDString)
            layerClient = LYRClient(appID: appID)
            layerClient.delegate = self
            layerClient.autodownloadMIMETypes = Set<NSObject>(arrayLiteral: "image/png")
            // Connect to Layer
            // See "Quick Start - Connect" for more details
            // https://developer.layer.com/docs/quick-start/ios#connect
            layerClient.connectWithCompletion() { (success: Bool, error: NSError?) in
                if !success {
                    println("Failed to connect to Layer: \(error)")
                } else {
                    self.authenticateLayerWithUserID(LQSCurrentUserID) { (success: Bool, error: NSError?) in
                        if !success {
                            println("Failed Authenticating Layer Client with error:\(error)")
                        } else {
                            println("successfully authenticated")
                        }
                    }
                }
            }
            
            // Register for push
            registerApplicationForPushNotifications(application)
            
            let navigationController: UINavigationController = self.window!.rootViewController as! UINavigationController
            let viewController: LQSViewController = navigationController.topViewController as! LQSViewController
            viewController.layerClient = layerClient
        }
        return true
    }

    // MARK - Push Notification Methods

    func registerApplicationForPushNotifications(application: UIApplication) {
        // Set up push notifications
        // For more information about Push, check out:
        // https://developer.layer.com/docs/guides/ios#push-notification
        
        // Checking if app is running iOS 8
        if (application.respondsToSelector("registerForRemoteNotifications")) {
            // Register device for iOS8
            let notificationSettings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound, categories: nil)
            application.registerUserNotificationSettings(notificationSettings)
            application.registerForRemoteNotifications()
        } else {
            // Register device for iOS7
            application.registerForRemoteNotificationTypes(UIRemoteNotificationType.Alert | UIRemoteNotificationType.Sound | UIRemoteNotificationType.Badge)
        }
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // Send device token to Layer so Layer can send pushes to this device.
        // For more information about Push, check out:
        // https://developer.layer.com/docs/guides/ios#push-notification
        var error: NSError?
        let success = layerClient!.updateRemoteNotificationDeviceToken(deviceToken, error: &error)
        if (success) {
            println("Application did register for remote notifications: \(deviceToken)")
        } else {
            println("Failed updating device token with error: \(error)")
        }
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        // Get Message from Metadata
        var message: LYRMessage = messageFromRemoteNotification(userInfo)
        
        var error: NSError?
        let success = layerClient!.synchronizeWithRemoteNotification(userInfo, completion: { (changes, error) in
            if (changes != nil) {
                if (changes!.count > 0) {
                    message = self.messageFromRemoteNotification(userInfo)
                    completionHandler(UIBackgroundFetchResult.NewData)
                } else {
                    completionHandler(UIBackgroundFetchResult.NoData)
                }
            } else {
                completionHandler(UIBackgroundFetchResult.Failed)
            }
        })
        
        if (success) {
            println("Application did complete remote notification sync")
        } else {
            println("Failed processing push notification with error: \(error)")
            completionHandler(UIBackgroundFetchResult.NoData)
        }
    }

    func messageFromRemoteNotification(remoteNotification: NSDictionary?) -> LYRMessage {
        let LQSPushMessageIdentifierKeyPath = "layer.message_identifier"
        
        // Retrieve message URL from Push Notification
        let messageURL = NSURL(string: remoteNotification!.valueForKeyPath(LQSPushMessageIdentifierKeyPath) as! String)
        
        // Retrieve LYRMessage from Message URL
        let query: LYRQuery = LYRQuery(queryableClass: LYRMessage.self)
        query.predicate = LYRPredicate(property: "identifier", predicateOperator: LYRPredicateOperator.IsIn, value: NSSet(object: messageURL!))
        
        var error: NSError?
        let messages: NSOrderedSet? = self.layerClient!.executeQuery(query, error: &error)
        if (error == nil) {
            println("Query contains \(messages!.count) messages")
            let message: LYRMessage = messages!.firstObject as! LYRMessage
            let messagePart: LYRMessagePart = message.parts[0] as! LYRMessagePart
            println("Pushed Message Contents: \(NSString(data: messagePart.data, encoding: NSUTF8StringEncoding))")
        } else {
            println("Query failed with error \(error)")
        }
        
        return messages!.firstObject as! LYRMessage
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK - Layer Authentication Methods

    func authenticateLayerWithUserID(userID: String, completion: ((success: Bool, error: NSError?) -> Void)) {
        if let layerClient = layerClient {
            if layerClient.authenticatedUserID != nil {
                println("Layer Authenticated as User \(layerClient.authenticatedUserID)")
                completion(success: true, error: nil)
                return
            }

            // Authenticate with Layer
            // See "Quick Start - Authenticate" for more details
            // https://developer.layer.com/docs/quick-start/ios#authenticate
            
            /*
             * 1. Request an authentication Nonce from Layer
             */
            layerClient.requestAuthenticationNonceWithCompletion() { (nonce: String!, error: NSError!) in
                if nonce.isEmpty {
                    completion(success: false, error: error)
                    return
                }
                
                /*
                 * 2. Acquire identity Token from Layer Identity Service
                 */
                self.requestIdentityTokenForUserID(userID, appID: layerClient.appID.UUIDString, nonce: nonce, completion: { (identityToken, error) in
                    if identityToken.isEmpty {
                        completion(success: false, error: error)
                        return
                    }
                    
                    /*
                     * 3. Submit identity token to Layer for validation
                     */
                    layerClient.authenticateWithIdentityToken(identityToken, completion: { (authenticatedUserID, error) in
                        if !authenticatedUserID.isEmpty {
                            completion(success: true, error: nil)
                            println("Layer Authenticated as User: \(authenticatedUserID)")
                        } else {
                            completion(success: false, error: error)
                        }
                    })
                })
            }
        }
    }

    func requestIdentityTokenForUserID(userID: String, appID: String, nonce: String, completion: ((identityToken: String, error: NSError?) -> Void)) {
        let identityTokenURL = NSURL(string: "https://layer-identity-provider.herokuapp.com/identity_tokens")
        let request = NSMutableURLRequest(URL: identityTokenURL!)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let parameters = ["app_id": appID, "user_id": userID, "nonce": nonce]
        let requestBody: NSData? = NSJSONSerialization.dataWithJSONObject(parameters, options: nil, error: nil)
        request.HTTPBody = requestBody
        
        let sessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfiguration)
        session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
            if error != nil {
                completion(identityToken: "", error: error)
                return
            }
            
            // Deserialize the response
            let responseObject: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as! NSDictionary
            if responseObject.valueForKey("error") == nil {
                var identityToken = responseObject["identity_token"] as! String?
                let token: String = (identityToken != nil) ? identityToken! : ""
                completion(identityToken: token, error: nil);
            } else {
                let domain = "layer-identity-provider.herokuapp.com"
                let code = responseObject["status"] as! Int?
                let userInfo = [ NSLocalizedDescriptionKey: "Layer Identity Provider Returned an Error.",
                                 NSLocalizedRecoverySuggestionErrorKey: "There may be a problem with your APPID." ]
               
                var error: NSError = NSError(domain: domain, code: code!, userInfo: userInfo)
                completion(identityToken: "", error: error)
            }
        }).resume()
    }

    // - MARK LYRClientDelegate Delegate Methods

    func layerClient(client: LYRClient, didReceiveAuthenticationChallengeWithNonce nonce: String) {
        println("Layer Client did recieve authentication challenge with nonce: \(nonce)")
    }

    func layerClient(client: LYRClient, didAuthenticateAsUserID userID: String) {
        println("Layer Client did recieve authentication nonce")
    }

    func layerClientDidDeauthenticate(client: LYRClient) {
        println("Layer Client did deauthenticate")
    }

    func layerClient(client: LYRClient, didFinishSynchronizationWithChanges changes: [AnyObject]) {
        println("Layer Client did finish sychronization")
    }

    func layerClient(client: LYRClient, didFailSynchronizationWithError error: NSError) {
        println("Layer Client did fail synchronization with error: \(error)")
    }

    func layerClient(client: LYRClient, willAttemptToConnect attemptNumber: UInt, afterDelay delayInterval: NSTimeInterval, maximumNumberOfAttempts attemptLimit: UInt) {
        println("Layer Client will attempt to connect")
    }

    func layerClientDidConnect(client: LYRClient) {
        println("Layer Client did connect")
    }

    func layerClient(client: LYRClient, didLoseConnectionWithError error: NSError) {
        println("Layer Client did lose connection with error: \(error)")
    }

    func layerClientDidDisconnect(client: LYRClient) {
        println("Layer Client did disconnect")
    }

    // MARK - First Run Notification

    func showFirstTimeMessage() {
        let LQSApplicationHasLaunchedOnceDefaultsKey = "applicationHasLaunchedOnce"
        
        let standardUserDefaults = NSUserDefaults.standardUserDefaults()
        if (!standardUserDefaults.boolForKey(LQSApplicationHasLaunchedOnceDefaultsKey)) {
            standardUserDefaults.setBool(true, forKey: LQSApplicationHasLaunchedOnceDefaultsKey)
            standardUserDefaults.synchronize()
            
            // This is the first launch ever
            let alert: UIAlertView = UIAlertView(title: "Hello!",
                                                 message: "This is a very simple example of a chat app using Layer. Launch this app on a Simulator and a Device to start a 1:1 conversation. If you shake the Device the navbar color will change on both the Simulator and Device.",
                                                 delegate: self,
                                                 cancelButtonTitle: nil)
            alert.addButtonWithTitle("Got It!")
            alert.show()
        }
    }

    // MARK - Check if Sample App is using a valid app ID.

    func isValidAppID() -> Bool {
        if LQSLayerAppIDString == "LAYER_APP_ID" {
            return false
        }
        return true
    }

    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if alertView.buttonTitleAtIndex(buttonIndex) == "Ok" {
            abort()
        }
    }

}


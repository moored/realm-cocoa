//
//  AppDelegate.swift
//  RealmSwiftMigrationExample
//
//  Created by Ari Lazier on 7/14/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import UIKit
import Realm

// Old data models
/* V0
@interface Person : RLMObject
@property NSString *firstName;
@property NSString *lastName;
@property int age;
@end
*/

/* V1
@interface Person : RLMObject
@property NSString *fullName;   // combine firstName and lastName into single field
@property int age;
@end
*/

/* V2 */
class Pet : RLMObject {
    var name = ""
    var type = ""
}

class Person : RLMObject {
    var fullName = ""
    var age: Int = 0
    var pets = RLMArray(objectClassName: Pet.className())
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?

    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {


        // define a migration block
        // you can define this inline, but we will reuse this to migrate realm files from multiple versions
        // to the most current version of our data model
        let migrationBlock: RLMMigrationBlock = { (migration, oldSchemaVersion) in
            if oldSchemaVersion < 1 {
                migration.enumerateObjects(Person.className(), block: { (oldObject, newObject) in
                    if oldSchemaVersion < 1 {
                        // combine name fields into a single field
                        let firstName = oldObject["firstName"] as String
                        let lastName = oldObject["lastName"] as String
                        newObject["fullName"] = "\(firstName) \(lastName)"
                    }
                })
            }
            if oldSchemaVersion < 2 {
                migration.enumerateObjects(Person.className(), block: { (oldObject, newObject) in
                    // give JP a dog
                    if newObject["fullName"] as String == "JP McDonald" {
                        let jpsDog = Pet(object: ["Jimbo", "dog"])
                        newObject["pets"].addObject(jpsDog)
                    }
                })
            }

            // return the new schema version
            return 2;
        };

        //
        // Migrate the default realm over multiple data model versions
        //
        let docsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let defaultPath = docsPath.stringByAppendingPathComponent("default.realm")

        // copy over old data file for v0 data model
        let v0Path = NSBundle.mainBundle().resourcePath.stringByAppendingPathComponent("default-v0.realm")
        NSFileManager.defaultManager().removeItemAtPath(defaultPath, error: nil)
        NSFileManager.defaultManager().copyItemAtPath(v0Path, toPath: defaultPath, error: nil)

        // migrate default realm at v0 data model to the current version
        RLMRealm.migrateDefaultRealmWithBlock(migrationBlock)

        // print out all migrated objects in the default realm
        println("Migrated objects in the default Realm: \(Person.allObjects().description)")

        //
        // Migrate a realms at a custom paths
        //
        let v1Path = NSBundle.mainBundle().resourcePath.stringByAppendingPathComponent("default-v1.realm")
        let v2Path = NSBundle.mainBundle().resourcePath.stringByAppendingPathComponent("default-v2.realm")
        let realmv1Path = docsPath.stringByAppendingPathComponent("default-v1.realm")
        let realmv2Path = docsPath.stringByAppendingPathComponent("default-v2.realm")

        NSFileManager.defaultManager().removeItemAtPath(realmv1Path, error: nil)
        NSFileManager.defaultManager().copyItemAtPath(v1Path, toPath: realmv1Path, error: nil)
        NSFileManager.defaultManager().removeItemAtPath(realmv2Path, error: nil)
        NSFileManager.defaultManager().copyItemAtPath(v2Path, toPath: realmv2Path, error: nil)

        // migrate realms at custom paths
        RLMRealm.migrateRealmAtPath(realmv1Path, withBlock: migrationBlock)
        RLMRealm.migrateRealmAtPath(realmv2Path, withBlock: migrationBlock)

        // print out all migrated objects in the migrated realms
        let realmv1 = RLMRealm.realmWithPath(realmv1Path, readOnly: false, error: nil)
        println("Migrated objects in the Realm migrated from v1: \(Person.allObjectsInRealm(realmv1).description)")
        let realmv2 = RLMRealm.realmWithPath(realmv2Path, readOnly: false, error: nil)
        println("Migrated objects in the Realm migrated from v2: \(Person.allObjectsInRealm(realmv2).description)")

        return true
    }

}


//
//  CloudKitTest.swift
//  CloudKitTest
//
//  Created by Michael Shaw on 19/4/17.
//  Copyright © 2017 Michael Shaw. All rights reserved.
//

import Foundation
import CloudKit


func doStuff() {
  print("doing stuff")
  let privateDatabase = CKContainer.default().privateCloudDatabase
  let zone = CKRecordZone(zoneName: "test_zone")
  CKUtil.modifyZones(database: privateDatabase, save: [zone]) {
    print("zone created")
    if let rec = constructNewRecord(zoneId: zone.zoneID) {
      CKUtil.modifyRecords(database: privateDatabase, save: [rec]) {
        print("modify completed")
      }
    } else {
      print("couldnt construct rec")
    }
  }
}


func constructNewRecord(zoneId:CKRecordZoneID) -> CKRecord? {
  let recordId = CKRecordID(recordName: "big_one", zoneID: zoneId)
  let rec = CKRecord(recordType: "asset_failure", recordID: recordId)
  
  rec.setValue(Int64(12), forKey: "schemaVersion")
  rec.setValue("XYZ_ABC", forKey: "clientId")
  
  rec.setValue("ham_key", forKey: "key")
  rec.setValue(Int32(5), forKey: "generation")
  
  rec.setValue(Int64(14), forKey: "createdAtLocal")
  rec.setValue(true, forKey: "gzipped")
  
  rec.setValue("a", forKey: "minKey")
  rec.setValue("z", forKey: "maxKey")
  
  rec.setValue(Int32(14), forKey: "elements")
  rec.setValue(Int32(12), forKey: "dataLength")
  rec.setValue(Int32(85), forKey: "uncompressedDataLength")
  
//  Data.init(bytes: <#T##Array<UInt8>#>)
  
  var rawBytes : [UInt8] = []
  
  for i in 0..<50000 {
    rawBytes.append(UInt8(i % 200))
  }
  
  let data = Data(bytes: rawBytes)
  
  if let url = Files.writeDataToTmpFile(data: data, suffix: ".bin") {
    rec.setValue(CKAsset(fileURL: url), forKey: "asset")
    return rec
  } else {
    return nil
  }
}

struct CKUtil {
  public static func modifyZones(database:CKDatabase,
                            save: [CKRecordZone],
                            onSuccess: @escaping () -> ()) {
    let op = CKModifyRecordZonesOperation(recordZonesToSave: save, recordZoneIDsToDelete: [])
    op.modifyRecordZonesCompletionBlock = { (savedZones, deletedZones, error) in
      //    print("createZone ::: saved \(savedZones) deleted \(deletedZones) error \(error)")
      if let e = error {
        print("CK :: ModifyRecordZones :: error -> \(e)")
      } else {
        print("CK :: ModifyRecordZones :: no error")
        onSuccess()
      }
    }
    
    database.add(op)
  }
  
  public static func modifyRecords(database:CKDatabase,
                            save: [CKRecord], onSuccess: @escaping () -> ())  {
    let op = CKModifyRecordsOperation(recordsToSave: save, recordIDsToDelete: [])
    
    op.perRecordCompletionBlock = { (record, error) in
      if let e = error {
        print("CK :: ModifyRecords :: Record Error is -> \(e)")
      }
    }
    
    op.modifyRecordsCompletionBlock = { (savedRecords, deletedIds, error) in
      if let e = error {
        print("CK :: ModifyRecords :: modify has an error -> \(e)")
      } else {
        print("CK :: ModifyRecords :: no error")
        onSuccess()
      }
    }
    
    database.add(op)
  }
}

struct Files {
  public static func temporaryPath(suffix:String) -> URL {
    let fileName = String(format: "%@_%@", ProcessInfo.processInfo.globallyUniqueString, suffix)
    return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
  }
  
  public static func writeDataToTmpFile(data:Data, suffix:String) -> URL? {
    let url = temporaryPath(suffix: suffix)
    return throwableToOption { () -> URL in
      try data.write(to: url)
      return url
    }
  }
}

public func throwableToOption<T>(block: (() throws -> T)) -> T? {
  do {
    let r = try block()
    return r
  } catch _ as NSError {
    return nil
  }
}


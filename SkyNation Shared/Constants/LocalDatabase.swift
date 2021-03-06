//  LocalDatabase.swift
//  SkyNation
//  Created by Farini on 9/10/20.
//  Copyright © 2020 Farini. All rights reserved.

// MAP OF ISS
// --------------------
//        *
//   /|   |/
// -*-*-*-*-<
// /|    /
//  *
//
// ====================

import Foundation

class LocalDatabase {
    
    static let shared = LocalDatabase()
    
    var player:SKNPlayer?
    var station:Station?
    var vehicles:[SpaceVehicle] = [] // Vehicles that are travelling
    var stationBuilder:StationBuilder
    
    // MARK: - Builder
    static let stationBuilderFile = "StationBuilder.json"
    /// Initializes `StationBuilder` with the `Station` object, or none if this is a new game.
    private static func initializeStationBuilder() -> StationBuilder {
        if let station = LocalDatabase.loadStation() {
            let builder = StationBuilder(station: station)
            return builder
        } else {
            let builder = StationBuilder()
            return builder
        }
    }
    /// Public function to reload the Builder. Pass a Station, or reload from start. Useful to reload scene
    func reloadBuilder(newStation:Station?) -> StationBuilder {
        if let new = newStation {
            let builder = StationBuilder(station: new)
            return builder
        } else {
            let starter = StationBuilder()
            return starter
        }
    }
    func saveStationBuilder(builder:StationBuilder) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .prettyPrinted
        guard let encodedData:Data = try? encoder.encode(builder) else { fatalError() }
        
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB]
        bcf.countStyle = .file
        
        let dataSize = bcf.string(fromByteCount: Int64(encodedData.count))
        print("Saving Station Builder. Size: \(dataSize)")
        
        let fileUrl = LocalDatabase.folder.appendingPathComponent(LocalDatabase.stationBuilderFile)
        
        if !FileManager.default.fileExists(atPath: fileUrl.path) {
            FileManager.default.createFile(atPath: fileUrl.path, contents: encodedData, attributes: nil)
            print("File created")
            return
        }
        
        do{
            try encodedData.write(to: fileUrl, options: .atomic)
            print("Saved locally")
        }catch{
            print("Error writting data to local url: \(error)")
        }
        
    }
    
    // MARK: - Game Messages
    static let gameMessagesFile = "GameMessages.json"
    var gameMessages:[GameMessage] = []
    private static func loadMessages() -> [GameMessage] {
        
        print("Loading Messages")
        let finalUrl = LocalDatabase.folder.appendingPathComponent(gameMessagesFile)
        
        if !FileManager.default.fileExists(atPath: finalUrl.path){
            print("File doesn't exist")
//            return nil
            return []
        }
        
        do{
            let theData = try Data(contentsOf: finalUrl)
            
            do{
                let localData:[GameMessage] = try JSONDecoder().decode([GameMessage].self, from: theData)
                return localData
                
            }catch{
                // Decode JSON Error
                print("Error Decoding JSON: \(error)")
                return []
            }
        }catch{
            // First Do - let data error
            print("Error getting Data from URL: \(error)")
            return []
        }
    }
    func saveMessages() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .prettyPrinted
        guard let encodedData:Data = try? encoder.encode(gameMessages) else { fatalError() }
        
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB]
        bcf.countStyle = .file
        
        let dataSize = bcf.string(fromByteCount: Int64(encodedData.count))
        print("Saving Station Builder. Size: \(dataSize)")
        
        let fileUrl = LocalDatabase.folder.appendingPathComponent(LocalDatabase.gameMessagesFile)
        
        if !FileManager.default.fileExists(atPath: fileUrl.path) {
            FileManager.default.createFile(atPath: fileUrl.path, contents: encodedData, attributes: nil)
            print("File created")
            return
        }
        
        do{
            try encodedData.write(to: fileUrl, options: .atomic)
            print("Saved locally")
        }catch{
            print("Error writting data to local url: \(error)")
        }
    }
    
    // MARK: - Station
    static let stationFile = "Station.json"
    func saveStation(station:Station) {
        
        print("Should save station")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        guard let encodedData:Data = try? encoder.encode(station) else { fatalError() }
        print("Should save station 2")
        
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB]
        bcf.countStyle = .file
        
        let dataSize = bcf.string(fromByteCount: Int64(encodedData.count))
        print("Saving Game Size: \(dataSize)")
        
        let fileUrl = LocalDatabase.folder.appendingPathComponent(LocalDatabase.stationFile)
        
        if !FileManager.default.fileExists(atPath: fileUrl.path) {
            FileManager.default.createFile(atPath: fileUrl.path, contents: encodedData, attributes: nil)
            print("File created")
            return
        }
        
        do{
            try encodedData.write(to: fileUrl, options: .atomic)
            print("Saved locally")
        }catch{
            print("Error writting data to local url: \(error)")
        }
    }
    private static func loadStation() -> Station? {
        print("Loading Station")
        let finalUrl = LocalDatabase.folder.appendingPathComponent(stationFile)
        
        if !FileManager.default.fileExists(atPath: finalUrl.path){
            print("File doesn't exist")
            return nil
        }
        
        do{
            let theData = try Data(contentsOf: finalUrl)
            
            do{
                let localData:Station = try JSONDecoder().decode(Station.self, from: theData)
                return localData
                
            }catch{
                // Decode JSON Error
                print("Error Decoding JSON: \(error)")
                return nil
            }
        }catch{
            // First Do - let data error
            print("Error getting Data from URL: \(error)")
            return nil
        }
    }
    
    // MARK: - Space Vehicles - Travelling
    static let vehiclesFile = "Travelling.json"
    func saveVehicles() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        guard let encodedData:Data = try? encoder.encode(vehicles) else { fatalError() }
        print("Saving Travelling Vehicles")
        
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB]
        bcf.countStyle = .file
        
        let dataSize = bcf.string(fromByteCount: Int64(encodedData.count))
        print("Saving Vehicles Size: \(dataSize)")
        
        let fileUrl = LocalDatabase.folder.appendingPathComponent(LocalDatabase.vehiclesFile)
        
        if !FileManager.default.fileExists(atPath: fileUrl.path) {
            FileManager.default.createFile(atPath: fileUrl.path, contents: encodedData, attributes: nil)
            print("File created")
            return
        }
        
        do{
            try encodedData.write(to: fileUrl, options: .atomic)
            print("Saved locally")
        }catch{
            print("Error writting data to local url: \(error)")
        }
    }
    private static func loadVehicles() -> [SpaceVehicle] {
        
        print("Loading Travelling Vehicles")
        let finalUrl = LocalDatabase.folder.appendingPathComponent(vehiclesFile)
        
        if !FileManager.default.fileExists(atPath: finalUrl.path){
            print("File doesn't exist")
            return []
        }
        
        do{
            let theData = try Data(contentsOf: finalUrl)
            
            do{
                let localData:[SpaceVehicle] = try JSONDecoder().decode([SpaceVehicle].self, from: theData)
                return localData
                
            }catch{
                // Decode JSON Error
                print("Error Decoding JSON: \(error)")
                return []
            }
        }catch{
            // First Do - let data error
            print("Error getting Data from URL: \(error)")
            return []
        }
        
//        return []
    }
    
    // MARK: - Player
    private static let playerFile = "Player.json"
    func savePlayer(player:SKNPlayer) -> Bool {
        print("Save player not yet implemented")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        guard let encodedData:Data = try? encoder.encode(player) else { fatalError() }
        print("Saving Travelling Vehicles")
        
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB]
        bcf.countStyle = .file
        
        let dataSize = bcf.string(fromByteCount: Int64(encodedData.count))
        print("Saving Vehicles Size: \(dataSize)")
        
        let fileUrl = LocalDatabase.folder.appendingPathComponent(LocalDatabase.playerFile)
        
        if !FileManager.default.fileExists(atPath: fileUrl.path) {
            FileManager.default.createFile(atPath: fileUrl.path, contents: encodedData, attributes: nil)
            print("File created")
            return true
        } else {
            do {
                try encodedData.write(to: fileUrl, options: .atomic)
                print("Saved Player locally")
                return true
            }catch{
                print("Error writting data to local url: \(error)")
                return false
            }
        }
    }
    private static func loadPlayer() -> SKNPlayer? {
        
        print("Loading Player")
        let finalUrl = LocalDatabase.folder.appendingPathComponent(playerFile)
        
        if !FileManager.default.fileExists(atPath: finalUrl.path){
            print("File doesn't exist")
            return nil
        }
        
        do {
            let theData = try Data(contentsOf: finalUrl)
            
            do {
                let localPlayer:SKNPlayer = try JSONDecoder().decode(SKNPlayer.self, from: theData)
                return localPlayer
                
            }catch{
                // Decode JSON Error
                print("Error Decoding JSON: \(error)")
                return nil
            }
        }catch{
            // First Do - let data error
            print("Error getting Data from URL: \(error)")
            return nil
        }
    }
    
    // Accounting Problems
    var accountingProblems:[String] = []    // Set by Station.runAccounting
    
    // MARK: - Data Handling
    
    static var folder:URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else{
            fatalError("Default folder for ap not found")
        }
        return url
    }
    
    init() {
        
        // Player
        if let player = LocalDatabase.loadPlayer() {
            self.player = player
        }
        
        // Space Station
        if let ss = LocalDatabase.loadStation() {
            print("Loading Station")
            // Set the Station
            self.station = ss
            // Load builder for station
            let sBuilder = LocalDatabase.initializeStationBuilder()
            self.stationBuilder = sBuilder
        }else{
            print("Starting New Game")
            let sBuilder = LocalDatabase.initializeStationBuilder()
            self.stationBuilder = sBuilder
            self.station = Station(stationBuilder: sBuilder)
//            self.station = Station(builder: builder)
        }
        
        self.gameMessages = LocalDatabase.loadMessages()
        
        // Builder
        /*
        if let builder = LocalDatabase.loadBuilder() {
            print("Loading Builder")
            self.builder = builder
        }else{
            print("Starting new builder")
            builder = SerialBuilder()
        }
        */
        
        // Space Station
//        if let ss = LocalDatabase.loadStation() {
//            print("Loading Station")
//            self.station = ss
//        }else{
//            print("Starting New Station")
//            self.station = Station(builder: builder)
//        }
        
        
        // Vehicles
        let vehiclesArray = LocalDatabase.loadVehicles()
        self.vehicles = vehiclesArray
        
    }
    
}


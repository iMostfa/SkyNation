//
//  LifeSupportSystems.swift
//  SkyTestSceneKit
//
//  Created by Farini on 8/29/20.
//  Copyright © 2020 Farini. All rights reserved.
//

import Foundation

class LSSModel:ObservableObject {
    
    var station:Station
    
    @Published var air:AirComposition
    @Published var batteries:[Battery]                 // Batteries
    @Published var tanks:[Tank]                        // Tanks
    @Published var boxes:[StorageBox]
    @Published var inhabitants:Int                     // Count of
    
    // Air
    @Published var requiredAir:Int          // Sum  of modules' volume
    @Published var currentAir:Int           // Air Volume
    @Published var currentPressure:Double   // volume / required air
    @Published var airQuality:String = "Good"
    
    @Published var liquidWater:Int
    @Published var levelZ:Double
    @Published var levelZCap:Double
    @Published var solarPanels:[SolarPanel] = []
    @Published var levelO2:Double
    @Published var levelCO2:Double
    
    @Published var peripherals:[PeripheralObject]
    @Published var batteriesDelta:Int       // How much energy gainin/losing
    @Published var accountDate:Date
    
    /// Energy consumption of Peripherals
    @Published var consumptionPeripherals:Int
    /// Energy Consumption of Modules
    @Published var consumptionModules:Int
    /// Energy Produced
    @Published var energyProduction:Int
    
    @Published var accountingProblems:[String] = LocalDatabase.shared.accountingProblems
    
    // Timer
    var timer = Timer()
    @Published var counter:Int = 0
    
    init() {
        
        guard let myStation = LocalDatabase.shared.station else {
            fatalError("No station")
        }
        self.station = myStation
        self.accountDate = myStation.accountingDate
        
        // Batteries
        let batteryPack = myStation.truss.getBatteries()
        if !batteryPack.isEmpty {
            self.batteries = batteryPack
            var lz = 0
            var mz = 0
            for batt in batteryPack {
                lz += batt.current
                mz += batt.capacity
            }
            self.levelZ = Double(lz)
            self.levelZCap = Double(mz)
        }else{
            // For tests purposes
            let b1 = Battery(capacity: 1000, current: 800)
            self.batteries = [b1]
            self.levelZ = 800
            self.levelZCap = 1000
        }
        
        // Solar Panels
        self.solarPanels = myStation.truss.solarPanels
        var deltaZ:Int = 0
        for sp in myStation.truss.solarPanels {
            deltaZ += sp.maxCurrent()
        }
        self.energyProduction = deltaZ
        
        let modulesCount = myStation.labModules.count + myStation.habModules.count + myStation.bioModules.count
        
        // Peripherals
        self.peripherals = myStation.peripherals
        var energyFromPeripherals:Int = 0
        for device in myStation.peripherals {
            energyFromPeripherals += device.peripheral.energyConsumption
        }
        self.consumptionPeripherals = energyFromPeripherals
        deltaZ -= energyFromPeripherals
        
        // Modules Consumption
        let modulesConsume = modulesCount * 4
        self.consumptionModules = modulesConsume
        deltaZ -= modulesConsume
        
        self.batteriesDelta = deltaZ
        
        
        // Air
        let reqAir = 200 * modulesCount
        self.requiredAir = reqAir
        
        let theAir = myStation.air
        air = theAir
        currentAir = theAir.volume
        currentPressure = Double(theAir.volume / (reqAir + 1)) * 100.0
        
        self.levelO2 = (Double(theAir.o2) / Double(theAir.volume)) * 100
        self.levelCO2 = (Double(theAir.co2) / Double(theAir.volume)) * 100
        
        
        
        
        
        // Tanks + Water
        self.tanks = myStation.truss.tanks
        
        var countWater:Int = 0
        for tank in myStation.truss.tanks {
            switch tank.type {
                case .h2o: countWater += tank.current
                default:continue
            }
        }
        self.liquidWater = countWater
        
        // Ingredients (Boxes)
        self.boxes = myStation.truss.extraBoxes
        
        // People
        inhabitants = myStation.people.count
        
        // After initialized
        self.peripherals.append(myStation.truss.antenna)
        updateEnergyLevels()
    }
    
    func updateDisplayVars() {
        
        // Batteries
        let batteryPack = station.truss.getBatteries()
        if !batteryPack.isEmpty {
            self.batteries = batteryPack
            var lz = 0
            var mz = 0
            for batt in batteryPack {
                lz += batt.current
                mz += batt.capacity
            }
            self.levelZ = Double(lz)
            self.levelZCap = Double(mz)
        }else{
            // For tests purposes
            let b1 = Battery(capacity: 1000, current: 800)
            self.batteries = [b1]
            self.levelZ = 800
            self.levelZCap = 1000
        }
        
        // Air
        let modCount = station.labModules.count + station.habModules.count + station.bioModules.count
        let reqAir = 200 * modCount
        self.requiredAir = reqAir
        
        let theAir = station.air
        air = theAir
        currentAir = theAir.volume
        currentPressure = Double(theAir.volume / (reqAir + 1)) * 100.0
        
        self.levelO2 = (Double(theAir.o2) / Double(theAir.volume)) * 100
        self.levelCO2 = (Double(theAir.co2) / Double(theAir.volume)) * 100
        
        // Tanks + Water
        let oxyT1 = Tank(type: .o2)
        let waterT = Tank(type: .h2o)
        self.liquidWater = waterT.capacity
        
        var otherTanks:[Tank] = []
        for t in station.truss.getTanks() {
            otherTanks.append(t)
        }
        if !otherTanks.isEmpty {
            self.tanks = otherTanks
        }else{
            tanks = [oxyT1, waterT]
        }
        
        print("Updating displays CO2:\(self.levelCO2)")
        print("Updating displays Z:\(self.levelZ)")
    }
    
    func releaseInAir(tank:Tank, amount:Int) {
        for idx in 0..<station.truss.tanks.count {
            if station.truss.tanks[idx].id == tank.id {
                var newTank = station.truss.tanks[idx]
                self.station.truss.tanks.remove(at: idx)
                newTank.current = tank.current - amount
                self.station.truss.tanks.append(newTank)
                self.tanks = self.station.truss.getTanks()
                switch tank.type {
                case .air:
                    let newAir = AirComposition(amount: amount)
                    self.station.air.o2 += newAir.o2
                    self.station.air.n2 += newAir.n2
                    self.updateDisplayVars()
                case .o2: self.station.air.o2 += amount
                default:
                    print("Something wrong. Can only open o2 and air")
                }
            }
        }
    }
    
    // Control Accounting
    
    func accountForPeople() {
        
        // Recharge Batteries
        recharge()
        
        // People
        let folks = station.getPeople()
        for person in folks {
            // Consume o2
            air.o2 -= 1
            if person.happiness < 20 {
                air.o2 -= 2
                air.co2 += 2
            }
            
            // generate co2
            air.co2 += 1
            
            // drink water
            liquidWater -= 2
            
            // evaporate water
            air.h2o += 1
            
//            // Energy
//            if !consumeEnergy(amt: 3) {
//                print("Not enough energy")
//            }
        }
        
        self.levelO2 = (Double(air.o2) / Double(air.volume)) * 100
        self.levelCO2 = (Double(air.co2) / Double(air.volume)) * 100
        
        // Scrub CO2
        let scrubbers = self.peripherals.filter({ $0.peripheral == PeripheralType.ScrubberCO2 }).count
        scrubCO2(amt: scrubbers)
        
        updateDisplayVars()
    }
    
    func openOxygenTank() {
        
        let o2Tanks = tanks.filter({ $0.type == .o2 })
        if o2Tanks.isEmpty {
            print("No O2 Tanks available")
            return
        }
        if let first = o2Tanks.first {
            print("Opening...")
            air.o2 += first.current
            air.volume += first.current
        }
        
    }
    
    func consumeOxygen(amt:Int) {
        air.o2 -= amt
        air.co2 += amt
        self.levelO2 = (Double(air.o2) / Double(air.volume)) * 100
        self.levelCO2 = (Double(air.co2) / Double(air.volume)) * 100
        if !consumeEnergy(amt: 10) {
            print("Not enough energy")
        }
    }
    
    func scrubCO2(amt:Int) {
        
        if air.co2 < 2 { return }
        
        if (consumeEnergy(amt: amt * 5) == true) {
            air.co2 = max(0, air.co2 - amt)
        }
        
        self.levelCO2 = (Double(air.co2) / Double(air.volume)) * 100
//        updateEnergyLevels()
        updateDisplayVars()
    }
    
    func consumeEnergy(amt:Int) -> Bool {
        for battery in batteries {
            if battery.consume(amt: amt) == true {
                updateEnergyLevels()
                return true
            }
        }
        return false
    }
    
    func updateEnergyLevels() {
        
        var totalCapacity:Int = 0
        var accumEnergy:Int = 0
        
        for battery in batteries {
            accumEnergy += battery.current
            totalCapacity += battery.capacity
        }
        
        self.levelZ = Double(accumEnergy)
        self.levelZCap = Double(totalCapacity)
    }
    
    func recharge() {
        for item in station.truss.solarPanels {
            bloop: for battery in batteries {
                if battery.charge() == true {
                    print("Charged from max current \(item.maxCurrent())")
                    break bloop
                }
            }
        }
    }
    
    // Real Accounting
    func runAccounting() {
        print("Going to run accounting...")
        station.runAccounting()
        accountingProblems = LocalDatabase.shared.accountingProblems
        
    }
    
    // Timer
    
    func prepTimer() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            self.incrementCounter()
        }
    }
    
    func incrementCounter() {
        print("Counter going \(counter)")
        self.counter += 1
        self.accountForPeople()
    }
    
    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            self.counter += 1
        }
    }
    
    func stop() {
        timer.invalidate()
    }
    
    func reset() {
        counter = 0
        timer.invalidate()
    }
    
    deinit {
        timer.invalidate()
    }
}
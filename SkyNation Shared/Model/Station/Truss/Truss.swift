//
//  Truss.swift
//  SkyTestSceneKit
//
//  Created by Farini on 9/13/20.
//  Copyright © 2020 Farini. All rights reserved.
//

import Foundation

class Truss:Codable {
    
    static let solarPanelsLimit:Int = 8
    static let extraBoxesLimit:Int = 12
    static let tanksLimit:Int = 18
    static let limitOfBatteries:Int = 10
    
    var solarPanels:[SolarPanel]
    var extraBoxes:[StorageBox]
    var tanks:[Tank]
    
    /// Gives energy to objects that need it
    var batteries:[Battery]
    
    /// Makes money for the `Station`
    var antenna:PeripheralObject
    
    /// Calculates the amount of money the `Antenna` makes
    func moneyFromAntenna() -> Int {
        var profits:Int = 100
        var level = antenna.level * 25
        if antenna.level > 3 {
            profits -= (antenna.level - 3) * 18
            level += antenna.level * 2
        }
        return profits + level
    }
    
//    func getBatteries() -> [Battery] {
//        return batteries
//    }
    
    func getTanks() -> [Tank] {
        var tankArray:[Tank] = []
        for tank in tanks {
            tankArray.append(tank)
        }
        return tankArray
    }
    
    func addRecipeSolar(panel:SolarPanel) {
        var panels = solarPanels
        panels.append(panel)
        self.solarPanels = panels
    }
    
    func addTank(tankType:TankType) -> Bool {
        if Truss.tanksLimit > tanks.count {
            var tankArray = tanks
            let newTank = Tank(type: tankType, full: true)
            tankArray.append(newTank)
            self.tanks = tankArray
            return true
        }
        return false
    }
    
    // FIXME: - Modifications
    // ⚠️ Needs to add and test:
    var tComponents:[TrussComponent]
    
    
    // NEW (Under test 12/08/2020)
//    func addNewSolarPanel() {
//        // Automatically places a new Solar Panel, after its made
//        // Check PeriPositions
//        // Count the objects to set "positionIndex"
//
//    }
    
    /**
     Adds a Solar Panel to the station and assigns it to a truss component.
     - Parameters:
     - panel: The SolarPanel object to be added
     - throws: An error when component can't be added (empty if none) */
    func addSolar(panel:SolarPanel) throws {
        
        // Check array of Solar panels. If not there, add it
        if !solarPanels.contains(where: { $0.id == panel.id }) {
            solarPanels.append(panel)
        }
        
        // Check if already assigned
        if let prevAssign = tComponents.filter({ $0.itemID == panel.id }).first {
            print("Throwing error: Solar Panel already assigned to component at position: \(prevAssign.posIndex)")
            throw AddingTrussItemProblem.ItemAlreadyAssigned
        }
        
        // Add it anywhere in components
        if let availableComponent = tComponents.filter({ $0.allowedType == .Solar && $0.itemID == nil }).sorted(by: { $0.posIndex < $1.posIndex }).first {
            let result = availableComponent.insert(solar: panel)
            if (result) {
                print("Adding solar success")
            } else {
                throw AddingTrussItemProblem.Invalidated
            }
        } else {
            throw AddingTrussItemProblem.NoAvailableComponent
        }
    }
    
    /// For Solar Panels only
    func autoAssignPanels() {
        
        var assignedIDs:[UUID] = []
        var availableComponents:[TrussComponent] = []
        var unassignedPanels:[SolarPanel] = []
        
        assignedIDs = tComponents.filter({ $0.allowedType == .Solar && $0.itemID != nil }).map({ $0.itemID! })
        availableComponents = tComponents.filter({ $0.allowedType == .Solar && $0.itemID == nil }).sorted(by: { $0.posIndex < $1.posIndex })
        
        unassignedPanels = solarPanels.filter({ !assignedIDs.contains($0.id) })
        
        for panel in unassignedPanels {
            print("Auto assigning Solar Panel ID:\(panel.id)")
            
            if let nextComponent:TrussComponent = availableComponents.first {
                let result = nextComponent.insert(solar: panel)
                print("Result (Solar Panel) > \(result)")
                availableComponents.removeFirst()
            } else {
                print("NO AVAILABLE SLOTS FOR THIS SOLAR PANEL")
            }
        }
    }
    
    func addNewRadiator() {
        // Automatically places a new Radiator (PeripheralObject), after its made
        // Add radiator here
    }
    
    // MARK: - Refills
    
    // FIXME: - Putting back in Containers
    // Put back....
    // Water
    // Pee (wasteLiquid)
    // Poop (wasteSolid)
    func refillTanks(of type:TankType, amount:Int) -> Int {
        var leftOvers:Int = amount
        let tanksArray = tanks.filter({ $0.type == type })
        
        for tank in tanksArray {
            tank.current = 0
            if leftOvers > 0 {
                let extra = tank.fillUp(leftOvers)
                leftOvers = max(extra, 0)
            }
            
            
//            if leftOvers <= 0 {
//                tank.current = 0
//            }else{
//                let input = leftOvers
//                let output = tank.fillUp(input)
//                leftOvers = output
//            }
        }
        return leftOvers
    }
    
    // Put back....
    // Water
    // Pee (wasteLiquid)
    // Poop (wasteSolid)
    func refillContainers(of type:Ingredient, amount:Int) -> Int {
        var leftOvers = amount
        let boxArray = extraBoxes.filter({ $0.type == type })
        for box in boxArray {
            if leftOvers <= 0 {
                return 0
            } else {
                let input = leftOvers
                let output = box.fillUp(input)
                leftOvers = output
            }
        }
        return leftOvers
    }
    
    // MARK: - Charging
    
    // Ingredients
    
    // Deprecate
    func canCharge(ingredients:[Ingredient:Int]) -> Bool {
        var pass:Bool = true
        for (ingr, qtty) in ingredients {
            let relevantBoxes = extraBoxes.filter({ $0.type == ingr })  // Filter
            let iHave = relevantBoxes.map({$0.current}).reduce(0, +)    // Reduce (see: https://stackoverflow.com/questions/24795130/finding-sum-of-elements-in-swift-array)
            if iHave < qtty {
                pass = false
            }
        }
        return pass
    }
    
    /**
     Checks if there are enough ingredients to cover the expenses.
    - Parameters:
    - ingredients: a key value of ingredient and quantity
    - Returns: An array of missing Ingredients (empty if none) */
    func validateResources(ingredients:[Ingredient:Int]) -> [Ingredient] {
        var lacking:[Ingredient] = []
        for (ingr, qtty) in ingredients {
            let relevantBoxes = extraBoxes.filter({ $0.type == ingr })  // Filter
            let iHave = relevantBoxes.map({$0.current}).reduce(0, +)    // Reduce (see: https://stackoverflow.com/questions/24795130/finding-sum-of-elements-in-swift-array)
            if iHave < qtty {
                lacking.append(ingr)
            }
        }
        return lacking
    }
    
    /**
     Pays (reduce amount) for the resources needed. Note: Not responsible for saving.
     - Parameters:
     - ingredients: a key value pair of ingredient and quantity
     - Returns: A `boolean` indicating whther it was successful. */
    func payForResources(ingredients:[Ingredient:Int]) -> Bool {
        
        // Loop through ingredients
        for (ingr, qtty) in ingredients {
            // Get boxes that have that ingredient
            let relevantBoxes = extraBoxes.filter({ $0.type == ingr })  // Filter
            var debt:Int = qtty
            boxLoop: for box in relevantBoxes {
                let boxQtty = box.current
                if boxQtty > debt {
                    box.current -= debt
                    debt = 0
                    break boxLoop
                } else if boxQtty == debt {
                    box.current = 0
                    debt = 0
                    // Box is empty. Remove it
                    extraBoxes.removeAll(where: { $0.id == box.id })
                    break boxLoop
                } else if boxQtty < debt {
                    debt -= boxQtty
                    box.current = 0
                    // Box is empty. Remove it
                    extraBoxes.removeAll(where: { $0.id == box.id })
                }
            }
            
            // End of box loop
            if debt > 0 {
                print("ERROR: COULD NOT PAY DEBT")
                return false
            }
        }
        // If it hasn't returned false at this point, its because ingredients are met.
        return true
    }
    
    // Tanks
    
    /**
     Removes a `Tank` object. (Usually when transferring to a `SpaceVehicle`, or when `Tank` is empty.
     - Parameters:
     - tank: The `Tank` object to be removed.
     - Returns: A `boolean` indicating whther it was successful. */
    func removeTank(tank:Tank) -> Bool {
        if let idx = tanks.firstIndex(of: tank) {
            tanks.remove(at: idx)
            return true
        } else {
            return false
        }
    }
    
    // Boxes
    
    /**
     Removes a `StorageBox` object. (Usually when transferring to a `SpaceVehicle`, or when `StorageBox` is empty.
     - Parameters:
     - tank: The `Tank` object to be removed.
     - Returns: A `boolean` indicating whther it was successful. */
    func removeContainer(box:StorageBox) -> Bool {
        guard let idx = extraBoxes.firstIndex(where: { $0.id == box.id }) else { return false }
        extraBoxes.remove(at: idx)
        return true
    }
    
    /// Remove empty boxes from storage, except the ones needed if empty.
    func clearEmptyBoxes() {
        // An array of box types that cannot be deleted.
        let doNotClear:[Ingredient] = [.Water, .wasteSolid, .wasteLiquid]
        
        for box in extraBoxes {
            if doNotClear.contains(box.type) == false {
                if let idx = extraBoxes.firstIndex(where: { $0.id == box.id }) {
                    if box.current <= 0 {
                        extraBoxes.remove(at: idx)
                    }
                }
            }
        }
    }
    
    // Energy
    
    /**
     Pays (consume) the amount of energy passed. Note: Not responsible for saving.
     - Parameters:
     - amount: the amount of energy to be consumed
     - Returns: A `boolean` indicating whther it was successful. */
    func consumeEnergy(amount:Int) -> Bool {
        var consumption = amount
        let ttl = batteries.map({ $0.current }).reduce(0, +)
        // return nil if not enough energy
        if ttl < consumption {
            return false
        } else {
            for b in batteries {
                if b.current < consumption {
                    consumption -= b.current
                    b.current = 0
                } else {
                    b.current -= consumption
                    consumption = 0
                }
            }
            return true
        }
    }
    
    func getAvailableEnergy() -> Int {
        return batteries.map({ $0.current }).reduce(0, +)
    }
    
    init() {
        // Solar Panels
        let solar1 = SolarPanel()
        self.solarPanels = [solar1]
        
        // Batteries
        let b1 = Battery(shopped: true)
        let b2 = Battery(shopped: true)
        self.batteries = [b1, b2]
        
        // Boxes
        let peepee = StorageBox(ingType: .wasteLiquid, current: 0)
        let poopoo = StorageBox(ingType: .wasteSolid, current: 0)
        self.extraBoxes = [peepee, poopoo]
        
        // Air, oxygen and water
        self.tanks = [Tank(type: .air, full: true), Tank(type: .o2, full: true), Tank(type: .h2o, full: true), Tank(type: .h2o, full: true), Tank(type: .h2o, full: true), Tank(type: .h2o, full: true), Tank(type: .o2, full: true), Tank(type: .o2, full: true)]
        
        // Antenna
        let newAntenna = PeripheralObject(peripheral: .Antenna)
        newAntenna.level = 1
        self.antenna = newAntenna
        
        // Components
        let tRobot = TrussComponent(index: 0)
        
        let sp1 = TrussComponent(index: 11)
        let solarAdd = sp1.insert(solar: solar1)
        if (!solarAdd) {
            print("Unable to add first solar panel")
        }
        let sp2 = TrussComponent(index: 12)
        let sp3 = TrussComponent(index: 13)
        let sp4 = TrussComponent(index: 14)
        let sp5 = TrussComponent(index: 15)
        let sp6 = TrussComponent(index: 16)
        let sp7 = TrussComponent(index: 17)
        let sp8 = TrussComponent(index: 18)
        
        let tR1 = TrussComponent(index: 31)
        let tR2 = TrussComponent(index: 32)
        let tR3 = TrussComponent(index: 33)
        let tR4 = TrussComponent(index: 34)
        
        self.tComponents = [tRobot, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, tR1, tR2, tR3, tR4]
         
    }
}

enum TrussItemType:String, Codable, CaseIterable {
    case Solar
    case Radiator
    case RoboArm
}

/// An object used to layout `PeripheralObject`and `SolarPanel` in the `Truss` so the user may place them where they want.
class TrussComponent:Codable, Identifiable, Equatable {
    
    /// The ID of this object
    var id:UUID
    
    /// The ID of the PeripheralObject, or SolarPanel
    var itemID:UUID?
    
    var posIndex:Int
    
    var allowedType:TrussItemType
    
    /// Implement this, to conveniently position and rotate object
//    func getPositionForPositionIndex() -> Model3D? {
//        return nil
//    }
    
    func getPosition() -> Vector3D? {
        switch posIndex {
            // Roboarm
            case 0: return Vector3D.zero
            
            // Solar Panels
            case 11: return Vector3D(x: 0, y: -18, z: 2.42)
            case 12: return Vector3D(x: 0, y: -14, z: 2.42)
            case 13: return Vector3D(x: 0, y: -18, z: -2.42)
            case 14: return Vector3D(x: 0, y: -14, z: -2.42)
            
            case 15: return Vector3D(x: 0, y: 14, z: 2.42)
            case 16: return Vector3D(x: 0, y: 18, z: 2.42)
            case 17: return Vector3D(x: 0, y: 14, z: -2.42)
            case 18: return Vector3D(x: 0, y: 18, z: -2.42)
            
            // Radiators
            case 31: return Vector3D(x: -2.42, y: -18, z: 0)
            case 32: return Vector3D(x: -2.42, y: -14, z: 0)
            case 33: return Vector3D(x: -2.42, y: 14, z: 0)
            case 34: return Vector3D(x: -2.42, y: 18, z: 0)
            
            default: return nil
        }
    }
    
    func getRotation() -> Vector3D? {
        switch posIndex {
            // Roboarm
            case 0: return Vector3D.zero
                
            // Solar Panels
            case 11: return Vector3D(x: GameLogic.radiansFrom(90), y: 0, z: GameLogic.radiansFrom(90))
            case 12: return Vector3D(x: GameLogic.radiansFrom(90), y: 0, z: GameLogic.radiansFrom(90))
            case 13: return Vector3D(x: GameLogic.radiansFrom(-90), y: 0, z: GameLogic.radiansFrom(90))
            case 14: return Vector3D(x: GameLogic.radiansFrom(-90), y: 0, z: GameLogic.radiansFrom(90))
                
            case 15: return Vector3D(x: GameLogic.radiansFrom(90), y: 0, z: GameLogic.radiansFrom(90))
            case 16: return Vector3D(x: GameLogic.radiansFrom(90), y: 0, z: GameLogic.radiansFrom(90))
            case 17: return Vector3D(x: GameLogic.radiansFrom(-90), y: 0, z: GameLogic.radiansFrom(90))
            case 18: return Vector3D(x: GameLogic.radiansFrom(-90), y: 0, z: GameLogic.radiansFrom(90))
                
            // Radiators
            case 31: return Vector3D(x: GameLogic.radiansFrom(90), y: GameLogic.radiansFrom(-90), z: 0)
            case 32: return Vector3D(x: GameLogic.radiansFrom(90), y: GameLogic.radiansFrom(-90), z: 0)
            case 33: return Vector3D(x: GameLogic.radiansFrom(90), y: GameLogic.radiansFrom(-90), z: 0)
            case 34: return Vector3D(x: GameLogic.radiansFrom(90), y: GameLogic.radiansFrom(-90), z: 0)
                
            default: return nil
        }
    }
    
    
    
    func insert(solar panel:SolarPanel) -> Bool {
        guard allowedType == .Solar && itemID == nil else { return false }
        self.itemID = panel.id
        return true
    }
    
    func insert(radiator:PeripheralObject) -> Bool {
        guard allowedType == .Radiator && itemID == nil else { return false }
        self.itemID = radiator.id
        return true
    }
    
    func remove(solar panel:SolarPanel) -> Bool {
        guard allowedType == .Solar else { return false }
        self.itemID = nil
        return true
    }
    
    func remove(radiator:PeripheralObject) -> Bool {
        guard allowedType == .Radiator else { return false }
        self.itemID = nil
        return true
    }
    
    init(index:Int) {
        self.id = UUID()
        switch index {
            case 0: self.allowedType = .RoboArm
            case 11...20: self.allowedType = .Solar
            case 31...50: self.allowedType = .Radiator
            default: fatalError()
        }
        self.posIndex = index
    }
    
    static func == (lhs: TrussComponent, rhs: TrussComponent) -> Bool {
        return lhs.id == rhs.id
    }
    
}


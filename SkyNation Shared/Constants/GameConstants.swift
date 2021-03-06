//  GameConstants.swift
//  SkyNation
//  Created by Carlos Farini on 12/18/20.

import SwiftUI

/*
class GameSettings {
    
    var showTutorial:Bool
    
    static let shared = GameSettings()
    private init () {
        var shouldShowTutorial:Bool = true
        if let station = LocalDatabase.shared.station {
            if let mod = station.habModules.first {
                print("We have a module: \(mod.name)")
                shouldShowTutorial = false
            }
        }
        self.showTutorial = shouldShowTutorial
    }
}
*/

/**
 Main Logic items for the game.
 Use this class to set limits, boundaries, and constraints */
struct GameLogic {
    
    /// The maximum amount of items in a new order (EarthOrder)
    static let earthOrderLimit:Int = 6
    static let orderTankPrice:Int = 10
    static let orderPersonPrice:Int = 15
    
    /// The default `capacity` of a battery
    static let batteryCapacity:Int = 100
    
    /// Amount of air a module requires
    static let airPerModule:Int = 225
    static let energyPerModule:Int = 4
    
    /// Water consumption per `Person`
    static let waterConsumption:Int = 2
    
    /// Cost of building a `BioBox` (Water)
    static let bioBoxWaterConsumption:Int = 3
    /// Cost of building a `BioBox` (Energy)
    static let bioBoxEnergyConsumption:Int = 7
    
    // MARK: - Funtions
    
    static func radiansFrom(_ degrees:Double) -> Double {
        return degrees * .pi/180
    }
    
    /**
     Calculates chances of an event happening - 100 default total
     - Parameter hit: The chance (divided by total)
     - Parameter total: The amount of trials (100 by default)
     - Returns: Whether the event happens, or not
     */
    static func chances(hit:Double, total:Double? = 100) -> Bool {
        guard let tot = total else { fatalError() }
        let result = Double.random(in: 0.0...tot)
        return result <= hit
    }
    
    // MARK: - Encrypting
    
    static func encrypt(string:String) -> String {
        guard !string.isEmpty else { return "" }
        let data = string.data(using: .utf8)
        if let encodedString = data?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            return encodedString
        }
        return ""
    }
    
    static func decrypt(string:String) -> String {
        guard !string.isEmpty else { return "" }
        if let decoded = Data(base64Encoded: string, options: Data.Base64DecodingOptions(rawValue: 0)).map({ String(data: $0, encoding: .utf8) }) {
            // Convert back to a string
            print("Decoded: \(decoded ?? "")")
            return decoded ?? ""
        }
        return ""
    }
}

/// Date and Number Formatters
struct GameFormatters {
    
    /// A Default Date Formatter
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// Longer date formatter
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        return formatter
    }()
    
    /// Default Number Formatter
    static let numberFormatter:NumberFormatter = {
        let format = NumberFormatter()
        format.minimumFractionDigits = 1
        format.maximumFractionDigits = 2
        format.numberStyle = NumberFormatter.Style.decimal
        #if os(macOS)
        format.hasThousandSeparators = true
        #else
        format.usesGroupingSeparator = true
        #endif
        
        return format
    }()
}

// MARK: - File System

class GameFiles {
    
    static let shared = GameFiles()
    
    private init() {
        
    }
    
    static var documentsFolder:URL {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else{
            fatalError("Default folder for ap not found")
        }
        return documents
    }
    
    static var appFolder:URL {
        guard let appSupportFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else{
            fatalError("Default folder for ap not found")
        }
        return appSupportFolder
    }
}

// MARK: - Graphics

/// The Colors the game uses
struct GameColors {
    static let greenBackground = Color.green
    static let lightBlue = Color.blue
}

enum GameSceneType {
    case SpaceStation
    case MarsColony
}


/// Images used by the game
struct GameImages {
    
    /// A SwiftUI Image for a given Skill
    static func imageForSkill(skill:Skills) -> Image {
        switch skill {
            case .Biologic: return Image("SkillBio")
            case .Datacomm: return Image("SkillData")
            case .Electric: return Image("SkillElectric")
            case .Material: return Image("SkillMaterial")
            case .Mechanic: return Image("SkillMechanic")
            case .Medic: return Image("SkillMedic")
            case .SystemOS: return Image("SkillSystems")
            case .Handy: return Image(systemName: "hand.wave.fill")
        }
    }
    
    static func imageForTank() -> Image {
        return Image("Tank")
    }
    
    static func commonSystemImage(name:String) -> SKNImage? {
        #if os(macOS)
        guard let im = NSImage(systemSymbolName: name, accessibilityDescription: name) else { return nil }
        im.isTemplate = true
        return im as SKNImage
        #else
        guard let image = UIImage(systemName: name)?.withTintColor(.white) else { fatalError() }
        return image.maskWithColor(color: .white)
        #endif
    }
    
    static var currencyImage:SKNImage {
        return SKNImage(named: "Currency")!
    }
    
}

struct GameWindow {
    static func closeWindow() {
        NotificationCenter.default.post(Notification(name: .closeView))
    }
}

// MARK: - Notifications

extension Notification.Name {
    
    static let URLRequestFailed  = Notification.Name("URLRequestFailed")        // Any URL Request that fails sends this messsage
    static let DidAddToFavorites = Notification.Name("DidAddToFavorites")       // Add To Favorites Notification
    static let UpdateSceneWithTech = Notification.Name("UpdateSceneWithTech")
    static let closeView = Notification.Name("CloseView")
    
}

// MARK: - Images

#if os(macOS)
public typealias SKNImage = NSImage
public typealias SCNColor = NSColor
#else
public typealias SKNImage = UIImage
public typealias SCNColor = UIColor
#endif

#if os(iOS)
extension UIImage {
    
    public func maskWithColor(color: UIColor) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        let rect = CGRect(origin: CGPoint.zero, size: size)
        
        color.setFill()
        self.draw(in: rect)
        
        context.setBlendMode(.sourceIn)
        context.fill(rect)
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resultImage
    }
    
}
#endif

// MARK: - Errors

enum AddingTrussItemProblem:Error {
    case NoAvailableComponent
    case ItemAlreadyAssigned
    case Invalidated
}

extension AddingTrussItemProblem: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .NoAvailableComponent:
                return NSLocalizedString("No available Truss component", comment: "")
            case .ItemAlreadyAssigned:
                return NSLocalizedString("This item has already been assigned", comment: "")
            case .Invalidated:
                return NSLocalizedString("Unknown error", comment: "")
        }
    }
}

// MARK: - SYSTEM COMMUNICATIONS

enum AchievementType:String, Codable, CaseIterable {
    
    case tech;
    case recipe;
    case vehicle;
    case deliveries;
    case plants;
    case learning;
    case marsLanding;
    case experience;
    
    func preString() -> String {
        switch self {
            case .tech: return "Researched tech: "
            case .recipe: return "Made a recipe: "
            case .vehicle: return "Space vehicle: "
            case .deliveries: return "Delivery arrived: "
            case .plants: return "DNA discovered: "
            case .learning: return "Person learning: "
            case .marsLanding: return "Landed on Mars: "
            case .experience: return "Achieved experience: "
        }
    }
}

struct GameAchievement:Codable {
    var type:AchievementType
    var date:Date
    var qtty:Int
}

class GameMessageBoard {
    
    static let shared:GameMessageBoard = GameMessageBoard()
    
    var messages:[GameMessage]
    
    private init() {
        messages = LocalDatabase.shared.gameMessages
    }
    
    func newAchievement(type:AchievementType, qtty:Int?) {
        
        self.messages = LocalDatabase.shared.gameMessages
        
        let theMessage = "Game Achievement! \(type.rawValue). \(qtty ?? 0). \(type.preString()) )"
        let newMessage = GameMessage(type: .Achievement, date: Date(), message: theMessage, ingredientRewards: [.Food:10])
        messages.append(newMessage)
        
        // Save
        LocalDatabase.shared.gameMessages = messages
        LocalDatabase.shared.saveMessages()
    }
}

struct GameMessage:Codable {
    
    var id:UUID = UUID()
    var type:GameMessageType
    var date:Date
    var message:String
    var isRead:Bool = false
    var isCollected:Bool = false
    
    // Optionals
    var tokenRewards:[UUID]?
    var ingredientRewards:[Ingredient:Int]?
}

enum GameMessageType:String, Codable, CaseIterable {
    
    case SystemWarning
    case SystemError
    
    case Achievement
    case Tutorial
    case ChatMessage
    case FreeDelivery
    
    case Other
}

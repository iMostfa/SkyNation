//
//  BioModController.swift
//  SkyTestSceneKit
//
//  Created by Farini on 9/24/20.
//  Copyright © 2020 Farini. All rights reserved.
//

import Foundation

enum BioModSelection {
    case notSelected
    case selected(box:BioBox)
    case building
}

class BioModController: ObservableObject {
    
    var module:BioModule
    var selectedBioBox:BioBox?
    var station:Station
    
    @Published var choosingDNA:Bool = false // Is choosing perfect DNA
    @Published var selection:BioModSelection
    @Published var dnaOption:PerfectDNAOption
    
    /// Available slots for new Box
    @Published var availableSlots:Int
    
    // GENETIC CODE
    @Published var selectedPopulation:[String] = []
    @Published var geneticLoops:Int = 0
    @Published var geneticFitString:String = ""
    @Published var geneticScore:Int = 0
    @Published var geneticRunning:Bool = false
    
    init(module:BioModule) {
        self.module = module
        self.selection = .notSelected
        self.station = LocalDatabase.shared.station!
        self.dnaOption = .strawberry
        
        // Get the BioModule's limit
        let limitation = BioModule.foodLimit
        // subtract all other boxes
        var currentPopulations:Int = 0
        for box in module.boxes {
            currentPopulations += box.population.count
        }
        let availableLimit = limitation - currentPopulations
        availableSlots = availableLimit
    }
    
    /// Selected **DNA**
    func didSelect(dna:PerfectDNAOption) {
        self.dnaOption = dna
        if let box = selectedBioBox {
            if box.population.count > 0 {
                print("Warning. There is already a population over here.")
            }
            print("This box is now making: \(dna.rawValue)")
            box.perfectDNA = dna.rawValue
        }else{
            print("Warning. No biobox selected")
        }
    }
    
    /// Selected **BioBox**
    func didSelect(box:BioBox) {
        self.selectedBioBox = box
        self.selection = .selected(box: box)
        guard let dna = PerfectDNAOption(rawValue: box.perfectDNA) else {
            return
        }
        self.dnaOption = dna
        
        self.selectedPopulation = box.population
//        if let dna = PerfectDNAOption(rawValue: box.perfectDNA) {
//            self.dnaOption = dna
//        }
    }
    
    func didChooseDNA(string:String) {
        selectedBioBox?.perfectDNA = string
        choosingDNA = false
    }
    
    
    
    // DEPRECATE
    func startBuildingBox() {
        /*
         To build a box, user needs to choose DNA, and LIMIT (Box size)
         Adding Feature:
         User may be able to discar some unuseful parts of population
        */
        // Get the BioModule's limit
        let limitation = BioModule.foodLimit
        // subtract all other boxes
        var currentPopulations:Int = 0
        for box in module.boxes {
            currentPopulations += box.population.count
        }
        let availableLimit = limitation - currentPopulations
        availableSlots = availableLimit
        // result will be the max of the new box
        // select perfect DNA
        // Start random population
    }
    
    /// Used when adding a new box. It brings the interface to build a box
    func startAddingBox() {
        self.selection = .building
    }
    
    /// Creates a new box
    func createNewBox(dna:PerfectDNAOption, size:Int) {
        print("Creating New Box. DNA: \(dna)")
        let box = BioBox(chosen: dna, size: size)
        module.boxes.append(box)
        
        // Update The Available Slots
        // Get the BioModule's limit
        let limitation = BioModule.foodLimit
        // subtract all other boxes
        var currentPopulations:Int = 0
        for box in module.boxes {
            currentPopulations += box.population.count
        }
        let availableLimit = limitation - currentPopulations
        availableSlots = availableLimit
        
        // Population is created at init of BioBox
        
        // Update Selection
        selection = .notSelected
        // Alternatively, we can set the selection to the newly created box
    }
    
    var dnaGenerator:DNAGenerator?
    
    func loadGeneticCode(box:BioBox) {
//        box.perfectDNA = dnaOption.rawValue
        let generator = DNAGenerator(controller: self, box: box)
        self.dnaGenerator = generator
        self.geneticLoops = generator.counter
        let score:Double = (1.0 / (Double(generator.bestLevel) + 1.0)) * 100.0
        self.geneticScore = Int(score)
        self.geneticRunning = true
        dnaGenerator?.main()
    }
    
    func updateGeneticCode(sender:DNAGenerator, finished:Bool = false) {
        // Update Population
        self.selectedPopulation = sender.populationStrings
        self.geneticLoops = sender.counter
        self.geneticFitString = sender.bestFit
        let score:Double = (1.0 / (Double(sender.bestLevel) + 1.0)) * 100.0
        self.geneticScore = Int(score)
        if (finished) {
            self.geneticRunning = false
            self.selectedBioBox!.population = sender.populationStrings
            self.selectedBioBox!.currentGeneration += sender.counter
        }
    }
    
    // DEPRECATE
    func shouldChooseDNA() -> Bool {
        return selectedBioBox?.perfectDNA.isEmpty ?? false
    }
    
}

class DNAGenerator {
    
    var controller:BioModController
    
    var perfectDNA:[UInt8]
    var populationDNAs:[[UInt8]]
    
    var dnaSize:Int
    var popCount:Int
    var generations:Int
    var mutationChance:Int
    
    /// The Best Fitting DNA (Healthiest)
    var bestFit:String
    var populationStrings:[String] = []
    
    /// Level is reversed 5...1 5 is worst, 0 is perfect fit
    var bestLevel:Int
    
    /// How many Generations
    var counter:Int
    var isRunning:Bool = false
    
    
    init(controller:BioModController, box:BioBox) {
        
        self.controller = controller
        
        let perfect:[UInt8] = box.perfectDNA.asciiArray
        self.perfectDNA = perfect
        
        let popStrings = box.population
        var popDNAs:[[UInt8]] = []
        for string in popStrings {
            popDNAs.append(string.asciiArray)
        }
        self.populationDNAs = popDNAs
        self.dnaSize = perfect.count
        self.popCount = popStrings.count
        self.generations = 20
        self.mutationChance = 100
        
        self.bestFit = populationStrings.first ?? "A"
        self.populationStrings = popStrings
        self.bestLevel = 1000
        self.counter = 0
        
        // Post init
        self.bestLevel = self.calculateFitness(dna: popDNAs[0], optimal: perfect)
    }
    
    /// Generates population. Pass the Chosen DNA and the size of the box. Return the Population (Strings)
    static func populate(dnaChoice:PerfectDNAOption, popSize:Int) -> [String] {
        let letters : [UInt8] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ_|-.@0123456789".asciiArray
        let len = UInt32(letters.count)
        
        // Generate Arrays of UInt8
        var pop = [[UInt8]]()
        for _ in 0..<popSize {
            var newDNA = [UInt8]()
            for _ in 0..<dnaChoice.rawValue.count {
                let rand = arc4random_uniform(len)
                let nextChar = letters[Int(rand)]
                newDNA.append(nextChar)
            }
            pop.append(newDNA)
        }
        
        // Convert Array to strings
        var popStrings:[String] = []
        for dna in pop {
            let dnaString = String(bytes: dna, encoding: .ascii) ?? ""
            if !dnaString.isEmpty {
                popStrings.append(dnaString.uppercased())
            }
        }
        
        return popStrings
    }
    
    /* calculated the fitness based on approximate string matching
     compares each character ascii value difference and adds that to a total fitness
     optimal string comparsion = 0 */
    private func calculateFitness(dna:[UInt8], optimal:[UInt8]) -> Int {
        
        var fitness = 0
        for c in 0...dna.count-1 {
            fitness += abs(Int(dna[c]) - Int(optimal[c]))
        }
        return fitness
    }
    
    /* randomly mutate the string */
    private func mutate(dna:[UInt8], mutationChance:Int, dnaSize:Int) -> [UInt8] {
        var outputDna = dna
        
        for i in 0..<dnaSize {
            let rand = Int(arc4random_uniform(UInt32(mutationChance)))
            if rand == 1 {
                outputDna[i] = randomChar()
            }
        }
        
        return outputDna
    }
    
    /* combine two parents to create an offspring parent = xy & yx, offspring = xx, yy */
    private func crossover(dna1:[UInt8], dna2:[UInt8], dnaSize:Int) -> (dna1:[UInt8], dna2:[UInt8]) {
        let pos = Int(arc4random_uniform(UInt32(dnaSize-1)))
        
        let dna1Index1 = dna1.index(dna1.startIndex, offsetBy: pos)
        let dna2Index1 = dna2.index(dna2.startIndex, offsetBy: pos)
        
        return (
            [UInt8](dna1.prefix(upTo: dna1Index1) + dna2.suffix(from: dna2Index1)),
            [UInt8](dna2.prefix(upTo: dna2Index1) + dna1.suffix(from: dna1Index1))
        )
    }
    
    /* function to return random canidate of a population randomally, but weight on fitness. */
    private func weightedChoice(items:[(item:[UInt8], weight:Double)]) -> (item:[UInt8], weight:Double) {
        var weightTotal = 0.0
        for itemTuple in items {
            weightTotal += itemTuple.weight;
        }
        
        var n = Double(arc4random_uniform(UInt32(weightTotal * 1000000.0))) / 1000000.0
        
        for itemTuple in items {
            if n < itemTuple.weight {
                return itemTuple
            }
            n = n - itemTuple.weight
        }
        return items[1]
    }
    
    func main() {
        
        self.isRunning = true
        
        DispatchQueue(label: "Background").async {
            
            // generate the starting random population
            var population:[[UInt8]] = self.populationDNAs // self.randomPopulation(populationSize: self.popCount, dnaSize: self.dnaSize)
            
            var fittest = [UInt8]()
            
            for generation in 0...self.generations {
                print("Generation \(generation) with random sample: \(String(bytes: population[0], encoding:.ascii)!)")
                
                var weightedPopulation = [(item:[UInt8], weight:Double)]()
                
                // calulcated the fitness of each individual in the population
                // and add it to the weight population (weighted = 1.0/fitness)
                for individual in population {
                    let fitnessValue = self.calculateFitness(dna: individual, optimal: self.perfectDNA)
                    
                    let pair = ( individual, fitnessValue == 0 ? 1.0 : 1.0/Double( fitnessValue ) )
                    
                    weightedPopulation.append(pair)
                }
                
                population = []
                
                // create a new generation using the individuals in the origional population
                for _ in 0...self.popCount/2 {
                    let ind1 = self.weightedChoice(items: weightedPopulation)
                    let ind2 = self.weightedChoice(items: weightedPopulation)
                    
                    let offspring = self.crossover(dna1: ind1.item, dna2: ind2.item, dnaSize: self.dnaSize)
                    
                    // append to the population and mutate
                    population.append(self.mutate(dna: offspring.dna1, mutationChance: self.mutationChance, dnaSize: self.dnaSize))
                    population.append(self.mutate(dna: offspring.dna2, mutationChance: self.mutationChance, dnaSize: self.dnaSize))
                }
                
                fittest = population[0]
                var minFitness = self.calculateFitness(dna: fittest, optimal: self.perfectDNA)
                
                // parse the population for the fittest string
                for indv in population {
                    let indvFitness = self.calculateFitness(dna: indv, optimal: self.perfectDNA)
                    if indvFitness < minFitness {
                        fittest = indv
                        minFitness = indvFitness
                    }
                }
                
                
                // Build the population string
                var newPopStrings:[String] = []
                for dna in population {
                    let dnaString = String(bytes: dna, encoding: .ascii) ?? ""
                    if !dnaString.isEmpty {
                        newPopStrings.append(dnaString)
                    }
                }
                
                // Update UI
                DispatchQueue.main.async {
                    self.bestFit = String(bytes: fittest, encoding: .ascii)!
                    self.counter += 1
                    self.populationDNAs = population
                    self.populationStrings = newPopStrings
                    self.controller.updateGeneticCode(sender: self)
                }
                
                if minFitness == 0 { break; }
                
                sleep(1)
            }
            
            
            print("fittest string: \(String(bytes: fittest, encoding: .ascii)!)")
            let fitnessLevel = self.calculateFitness(dna: fittest, optimal: self.perfectDNA)
            
            // Update UI
            DispatchQueue.main.async {
                self.bestLevel = fitnessLevel
                self.isRunning = false
                self.controller.updateGeneticCode(sender: self, finished: true)
            }
            
            
            print("Fitness Level: \(fitnessLevel)")
        }
    }
    
}

// MARK: - DNA Generator

class DNAMatcherModel:ObservableObject {
    
    var perfectDNA:[UInt8]
    var populationDNAs:[[UInt8]]
    
    var dnaSize:Int
    var popCount:Int
    var generations:Int
    var mutationChance:Int
    
    /// The Best Fitting DNA (Healthiest)
    @Published var bestFit:String
    
    @Published var populationStrings:[String] = []
    
    /// Level is reversed 5...1 5 is worst, 0 is perfect fit
    @Published var bestLevel:Int
    
    /// How many Generations
    @Published var counter:Int
    
    @Published var isRunning:Bool = false
    
    // MARK: - Static (Before Initializer)
    
    // DEPRECATE
    /// Initial population -  Generate complete random Strings, so the user can later hand pick the best DNAs
    static func generateInitialPopulation(count:Int) -> [[UInt8]] {
        let letters : [UInt8] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ_|-.@0123456789".asciiArray
        //let letters : [UInt8] = " !\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~".asciiArray
        let len = UInt32(letters.count)
        
        var pop = [[UInt8]]()
        
        let dnaOptions:[Int] = [5, 6, 7, 8]
        
        for _ in 0..<count {
            var dna = [UInt8]()
            for _ in 0..<dnaOptions.randomElement()! {
                let rand = arc4random_uniform(len)
                let nextChar = letters[Int(rand)]
                dna.append(nextChar)
            }
            pop.append(dna)
        }
        return pop
    }
    
    /// Generates population. Pass the Chosen DNA and the size of the box. Return the Population (Strings)
    static func populate(dnaChoice:PerfectDNAOption, popSize:Int) -> [String] {
        let letters : [UInt8] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ_|-.@0123456789".asciiArray
        let len = UInt32(letters.count)
        
        // Generate Arrays of UInt8
        var pop = [[UInt8]]()
        for _ in 0..<popSize {
            var newDNA = [UInt8]()
            for _ in 0..<dnaChoice.rawValue.count {
                let rand = arc4random_uniform(len)
                let nextChar = letters[Int(rand)]
                newDNA.append(nextChar)
            }
            pop.append(newDNA)
        }
        
        // Convert Array to strings
        var popStrings:[String] = []
        for dna in pop {
            let dnaString = String(bytes: dna, encoding: .ascii) ?? ""
            if !dnaString.isEmpty {
                popStrings.append(dnaString.uppercased())
            }
        }
        
        return popStrings
    }
    
    // MARK: - Initializer
    
    // DEPRECATE
    init(fitString:String, population:Int = 40, gens:Int = 20, mutate:Int = 100) {
        let fitDNA:[UInt8] = fitString.asciiArray
        perfectDNA = fitDNA
        dnaSize = fitDNA.count
        popCount = 40
        bestFit = "A"
        counter = 0
        bestLevel = 1000
        generations = gens
        mutationChance = mutate
        self.populationDNAs = []
        self.populationDNAs = randomPopulation(populationSize: popCount, dnaSize: fitDNA.count)
    }
    
    // DEPRECATE
    init(box:BioBox) {
        guard !box.perfectDNA.isEmpty else { fatalError() }
        perfectDNA = box.perfectDNA.asciiArray
        dnaSize = box.perfectDNA.count
        popCount = box.population.count
        generations = box.generations
        mutationChance = box.mutationChance
        bestLevel = 1000
        var thePopulation:[[UInt8]] = []
        for string in box.population {
            thePopulation.append(string.asciiArray)
        }
        bestFit = "A"
        counter = 0
        self.populationDNAs = thePopulation
    }
    
    // Funtions - Basic Setup
    
    // DEPRECATE
    func convertTo(box:BioBox) {
        guard !box.perfectDNA.isEmpty else { fatalError() }
        perfectDNA = box.perfectDNA.asciiArray
        dnaSize = box.perfectDNA.count
        popCount = box.population.count
        generations = box.generations
        mutationChance = box.mutationChance
        bestLevel = 1000
        var thePopulation:[[UInt8]] = []
        for string in box.population {
            if string.count == dnaSize {
                print("String count ok")
                thePopulation.append(string.asciiArray)
            }else{
                print("bad string: \(string)")
            }
        }
        if thePopulation.isEmpty {
            if !self.populationStrings.isEmpty && self.populationStrings.first!.count == dnaSize {
                print("using self population")
                thePopulation = self.populationDNAs
            }else{
                // Generate
                print("Generating Population")
                thePopulation = self.randomPopulation(populationSize: popCount, dnaSize: dnaSize)
            }
            
        }
        bestFit = "A"
        counter = 0
        self.populationDNAs = thePopulation
    }
    
    
    /* returns a random population, used to start the evolution */
    func randomPopulation(populationSize: Int, dnaSize: Int) -> [[UInt8]] {
        
        let letters : [UInt8] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ_|-.@0123456789".asciiArray
        //let letters : [UInt8] = " !\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~".asciiArray
        let len = UInt32(letters.count)
        
        var pop = [[UInt8]]()
        
        for _ in 0..<populationSize {
            var dna = [UInt8]()
            for _ in 0..<dnaSize {
                let rand = arc4random_uniform(len)
                let nextChar = letters[Int(rand)]
                dna.append(nextChar)
            }
            pop.append(dna)
        }
        return pop
    }
    
    /* calculated the fitness based on approximate string matching
     compares each character ascii value difference and adds that to a total fitness
     optimal string comparsion = 0 */
    private func calculateFitness(dna:[UInt8], optimal:[UInt8]) -> Int {
        
        var fitness = 0
        for c in 0...dna.count-1 {
            fitness += abs(Int(dna[c]) - Int(optimal[c]))
        }
        return fitness
    }
    
    /* randomly mutate the string */
    private func mutate(dna:[UInt8], mutationChance:Int, dnaSize:Int) -> [UInt8] {
        var outputDna = dna
        
        for i in 0..<dnaSize {
            let rand = Int(arc4random_uniform(UInt32(mutationChance)))
            if rand == 1 {
                outputDna[i] = randomChar()
            }
        }
        
        return outputDna
    }
    
    /* combine two parents to create an offspring parent = xy & yx, offspring = xx, yy */
    private func crossover(dna1:[UInt8], dna2:[UInt8], dnaSize:Int) -> (dna1:[UInt8], dna2:[UInt8]) {
        let pos = Int(arc4random_uniform(UInt32(dnaSize-1)))
        
        let dna1Index1 = dna1.index(dna1.startIndex, offsetBy: pos)
        let dna2Index1 = dna2.index(dna2.startIndex, offsetBy: pos)
        
        return (
            [UInt8](dna1.prefix(upTo: dna1Index1) + dna2.suffix(from: dna2Index1)),
            [UInt8](dna2.prefix(upTo: dna2Index1) + dna1.suffix(from: dna1Index1))
        )
    }
    
    /* function to return random canidate of a population randomally, but weight on fitness. */
    private func weightedChoice(items:[(item:[UInt8], weight:Double)]) -> (item:[UInt8], weight:Double) {
        var weightTotal = 0.0
        for itemTuple in items {
            weightTotal += itemTuple.weight;
        }
        
        var n = Double(arc4random_uniform(UInt32(weightTotal * 1000000.0))) / 1000000.0
        
        for itemTuple in items {
            if n < itemTuple.weight {
                return itemTuple
            }
            n = n - itemTuple.weight
        }
        return items[1]
    }
    
    func main() {
        
        self.isRunning = true
        
        DispatchQueue(label: "Background").async {
            // generate the starting random population
            var population:[[UInt8]] = self.populationDNAs // self.randomPopulation(populationSize: self.popCount, dnaSize: self.dnaSize)
            
            var fittest = [UInt8]()
            
            for generation in 0...self.generations {
                print("Generation \(generation) with random sample: \(String(bytes: population[0], encoding:.ascii)!)")
                
                var weightedPopulation = [(item:[UInt8], weight:Double)]()
                
                // calulcated the fitness of each individual in the population
                // and add it to the weight population (weighted = 1.0/fitness)
                for individual in population {
                    let fitnessValue = self.calculateFitness(dna: individual, optimal: self.perfectDNA)
                    
                    let pair = ( individual, fitnessValue == 0 ? 1.0 : 1.0/Double( fitnessValue ) )
                    
                    weightedPopulation.append(pair)
                }
                
                population = []
                
                // create a new generation using the individuals in the origional population
                for _ in 0...self.popCount/2 {
                    let ind1 = self.weightedChoice(items: weightedPopulation)
                    let ind2 = self.weightedChoice(items: weightedPopulation)
                    
                    let offspring = self.crossover(dna1: ind1.item, dna2: ind2.item, dnaSize: self.dnaSize)
                    
                    // append to the population and mutate
                    population.append(self.mutate(dna: offspring.dna1, mutationChance: self.mutationChance, dnaSize: self.dnaSize))
                    population.append(self.mutate(dna: offspring.dna2, mutationChance: self.mutationChance, dnaSize: self.dnaSize))
                }
                
                fittest = population[0]
                var minFitness = self.calculateFitness(dna: fittest, optimal: self.perfectDNA)
                
                // parse the population for the fittest string
                for indv in population {
                    let indvFitness = self.calculateFitness(dna: indv, optimal: self.perfectDNA)
                    if indvFitness < minFitness {
                        fittest = indv
                        minFitness = indvFitness
                    }
                }
                
                
                // Build the population string
                var newPopStrings:[String] = []
                for dna in population {
                    let dnaString = String(bytes: dna, encoding: .ascii) ?? ""
                    if !dnaString.isEmpty {
                        newPopStrings.append(dnaString)
                    }
                }
                
                // Update UI
                DispatchQueue.main.async {
                    self.bestFit = String(bytes: fittest, encoding: .ascii)!
                    self.counter += 1
                    self.populationDNAs = population
                    self.populationStrings = newPopStrings
                }
                
                if minFitness == 0 { break; }
                
                sleep(1)
            }
            
            
            print("fittest string: \(String(bytes: fittest, encoding: .ascii)!)")
            let fitnessLevel = self.calculateFitness(dna: fittest, optimal: self.perfectDNA)
            
            // Update UI
            DispatchQueue.main.async {
                self.bestLevel = fitnessLevel
                self.isRunning = false
            }
            
            
            print("Fitness Level: \(fitnessLevel)")
        }
        
        //        // generate the starting random population
        //        var population:[[UInt8]] = randomPopulation(populationSize: POP_SIZE, dnaSize: DNA_SIZE)
        //
        //        var fittest = [UInt8]()
        //
        //        for generation in 0...GENERATIONS {
        //            print("Generation \(generation) with random sample: \(String(bytes: population[0], encoding:.ascii)!)")
        //
        //            var weightedPopulation = [(item:[UInt8], weight:Double)]()
        //
        //            // calulcated the fitness of each individual in the population
        //            // and add it to the weight population (weighted = 1.0/fitness)
        //            for individual in population {
        //                let fitnessValue = calculateFitness(dna: individual, optimal: Optimal)
        //
        //                let pair = ( individual, fitnessValue == 0 ? 1.0 : 1.0/Double( fitnessValue ) )
        //
        //                weightedPopulation.append(pair)
        //            }
        //
        //            population = []
        //
        //            // create a new generation using the individuals in the origional population
        //            for _ in 0...POP_SIZE/2 {
        //                let ind1 = weightedChoice(items: weightedPopulation)
        //                let ind2 = weightedChoice(items: weightedPopulation)
        //
        //                let offspring = crossover(dna1: ind1.item, dna2: ind2.item, dnaSize: DNA_SIZE)
        //
        //                // append to the population and mutate
        //                population.append(mutate(dna: offspring.dna1, mutationChance: MUTATION_CHANCE, dnaSize: DNA_SIZE))
        //                population.append(mutate(dna: offspring.dna2, mutationChance: MUTATION_CHANCE, dnaSize: DNA_SIZE))
        //            }
        //
        //            fittest = population[0]
        //            var minFitness = calculateFitness(dna: fittest, optimal: Optimal)
        //
        //            // parse the population for the fittest string
        //            for indv in population {
        //                let indvFitness = calculateFitness(dna: indv, optimal: Optimal)
        //                if indvFitness < minFitness {
        //                    fittest = indv
        //                    minFitness = indvFitness
        //                }
        //            }
        //            self.bestFit = String(bytes: fittest, encoding: .ascii)!
        //            self.counter += 1
        //            if minFitness == 0 { break; }
        //        }
        //
        //
        //        print("fittest string: \(String(bytes: fittest, encoding: .ascii)!)")
        //        let fitnessLevel = calculateFitness(dna: fittest, optimal: Optimal)
        //        self.bestLevel = fitnessLevel
        //
        //        print("Fitness Level: \(fitnessLevel)")
    }
}

// HELPERS
/*
 String extension to convert a string to ascii value
 */
extension String {
    var asciiArray: [UInt8] {
        return unicodeScalars.filter{$0.isASCII}.map{UInt8($0.value)}
    }
}

/*
 helper function to return a random character string
 */
func randomChar() -> UInt8 {
    
    let letters : [UInt8] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ_|-.@0123456789".asciiArray
    //    let letters : [UInt8] = " !\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~".asciiArray
    let len = UInt32(letters.count-1)
    
    let rand = Int(arc4random_uniform(len))
    return letters[rand]
}

// END HELPERS

/*
 gen.swift is a direct port of cfdrake's helloevolve.py from Python 2.7 to Swift 3
 -------------------- https://gist.github.com/cfdrake/973505 ---------------------
 gen.swift implements a genetic algorithm that starts with a base
 population of randomly generated strings, iterates over a certain number of
 generations while implementing 'natural selection', and prints out the most fit
 string.
 The parameters of the simulation can be changed by modifying one of the many
 global variables. To change the "most fit" string, modify OPTIMAL. POP_SIZE
 controls the size of each generation, and GENERATIONS is the amount of
 generations that the simulation will loop through before returning the fittest
 string.
 This program subject to the terms of The MIT License listed below.
 ----------------------------------------------------------------------------------
 Copyright (c) 2016 Blaine Rothrock
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in the
 Software without restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
 Software, and to permit persons to whom the Software is furnished to do so, subject
 to the following conditions:
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 """
 */
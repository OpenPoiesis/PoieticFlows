//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 17/07/2022.
//

@preconcurrency import ArgumentParser
import SystemPackage
import Foundation

import PoieticCore
import PoieticFlows

extension PoieticTool {
    struct Run: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Run the simulation and generate output")

        @OptionGroup var options: Options

        @Option(name: [.long, .customShort("s")],
                help: "Number of steps to run")
        var steps: Int?
        
        @Option(name: [.long, .customShort("t")],
                help: "Time delta")
        var timeDelta: Double = 1.0
        
        @Option(name: [.customLong("solver")],
                help: "Type of the solver to be used for computation")
        var solverName: String = "euler"

        enum OutputFormat: String, CaseIterable, ExpressibleByArgument{
            case csv = "csv"
//            case json = "json"
            case gnuplot = "gnuplot"
            var defaultValueDescription: String { "csv" }
            
            static var allValueStrings: [String] {
                OutputFormat.allCases.map { "\($0)" }
            }
        }
        @Option(name: [.long, .customShort("f")], help: "Output format")
        var outputFormat: OutputFormat = .csv

        // TODO: Deprecate
        @Option(name: [.customLong("variable"), .customShort("V")],
                help: "Values to observe in the output; can be object IDs or object names.")
        var outputNames: [String] = []

        // TODO: Deprecate
        @Option(name: [.customLong("constant"), .customShort("c")],
                       help: "Set (override) a value of a constant node in a form 'attribute=value'")
        var overrideValues: [String] = []

        /// Path to the output directory.
        /// The generated files are:
        /// out/
        ///     simulation.csv
        ///     chart-NAME.csv
        ///     data-NAME.csv
        ///
        /// output format:
        ///     - simple: full state only, as CSV
        ///     - json: full state with all outputs as structured JSON
        ///     - dir: directory with all outputs as CSVs (no stdout)
        ///
        @Option(name: [.customLong("output"), .customShort("o")], help: "Output path. Default or '-' is standard output.")
        var outputPath: String = "-"
        
        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)
            let design = try env.open()

            guard let solverType = Solver.registeredSolvers[solverName] else {
                throw ToolError.unknownSolver(solverName)
            }
            let frame = design.currentFrame
            let compiledModel = try compile(frame)
            let simulator = Simulator(model: compiledModel, solverType: solverType)

            // Collect names of nodes to be observed
            // -------------------------------------------------------------
            let variables = compiledModel.stateVariables
            if outputNames.isEmpty {
                outputNames = Array(variables.map {$0.name})
            }
            else {
                let allNames = compiledModel.stateVariables.map { $0.name }
                let unknownNames = outputNames.filter {
                    !allNames.contains($0)
                }
                guard unknownNames.isEmpty else {
                    throw ToolError.unknownVariables(unknownNames)
                }
            }
            // TODO: We do not need this any more
            var outputVariables: [StateVariable] = []
            for name in outputNames {
                let variable = variables.first { $0.name == name }!
                outputVariables.append(variable)
            }

            // TODO: Add JSON for controls
            // Collect constants to be overridden during initialization.
            // -------------------------------------------------------------
            var overrideConstants: [ObjectID: Double] = [:]
            for item in overrideValues {
                guard let split = parseValueAssignment(item) else {
                    throw ToolError.invalidAttributeAssignment(item)
                }
                let (key, stringValue) = split
                guard let doubleValue = Double(stringValue) else {
                    throw ToolError.typeMismatch("constant override '\(key)'", stringValue, "double")
                }
                guard let variable = compiledModel.variable(named: key) else {
                    throw ToolError.unknownObjectName(key)
                }
                overrideConstants[variable.id] = doubleValue
            }
            
            // Create and initialize the solver
            // -------------------------------------------------------------
            try simulator.initializeState(override: overrideConstants)
            
            // Run the simulation
            // -------------------------------------------------------------
            // Try to get number of steps providede in the design.
            let defaultSteps = simulator.compiledModel.simulationDefaults?.simulationSteps
            let actualSteps = steps ?? defaultSteps ?? 10
            try simulator.run(actualSteps)

            switch outputFormat {
            case .csv:
                try writeCSV(path: outputPath,
                             variables: outputVariables,
                             states: simulator.output)
            case .gnuplot:
                try writeGnuplotBundle(path: outputPath,
                                       frame: frame,
                                       compiledModel: compiledModel,
                                       output: simulator.output)
//            case .json:
//                try writeJSON(path: outputPath,
//                              variables: outputVariables,
//                              states: simulator.output)
            }

            try env.close()
        }
    }
}

func writeCSV(path: String,
              variables: [StateVariable],
              states: [SimulationState]) throws {
    let header: [String] = variables.map { $0.name }

    // TODO: Step
    let writer: CSVWriter
    if path == "-" {
        writer = try CSVWriter(.standardOutput)
    }
    else {
        writer = try CSVWriter(path: path)
    }
    try writer.write(row: header)
    for state in states {
        var row: [String] = []
        for variable in variables {
            let value = state[variable.index]
            row.append(try value.stringValue())
        }
        try writer.write(row: row)
    }
    try writer.close()
    
}

// TODO: This is quickly put together, just to see what we need. Requires proper design.
/// Write a Gnuplot directory bundle.
///
/// The function will create a directory at `path` if it does not exist and then
/// creates the following files:
///
/// - `output.csv` – all the simulation states
/// - `chart_NAME.gnuplot` – one file for every chart where the NAME is the
///    chart object name.
///
/// If the path is '-' then the current directory will be used.
///
func writeGnuplotBundle(path: String,
                        frame: Frame,
                        compiledModel: CompiledModel,
                        output: [SimulationState]) throws {
    let path = if path == "-" { "." } else { path }
    let view = StockFlowView(frame)
    let variables = compiledModel.stateVariables
    let fm = FileManager()
    try fm.createDirectory(atPath: path, withIntermediateDirectories: true)
    let dataFileName = "output.csv"
    // Write all the output
    try writeCSV(path: path + "/" + dataFileName,
                 variables: compiledModel.stateVariables,
                 states: output)
    
    let timeIndex = variables.firstIndex { $0.name == "time" }!

    // Write chart output
    for chart in view.charts {
        
        let chartName = chart.node.name!
        // TODO: Plot all the series
        if chart.series.count > 1 {
            print("NOTE: Printing only the first series, multiple series is not yet supported")
        }
        guard let series = chart.series.first else {
            print("WARNING: Chart '\(chart.node.name ?? "(unnamed)")' has no series.")
            continue
        }
        let seriesIndex = variables.firstIndex { $0.name == series.name }!
        let imageFile = path + "chart_\(chartName).png"
        
        let gnuplotCommand =
        """
        set datafile separator ',';
        set key autotitle columnhead;
        set terminal png;
        set output '\(imageFile)';
        plot '\(dataFileName)' using \(timeIndex + 1):\(seriesIndex + 1) with lines;
        """

        let gnuplotCommandPath = path + "/" + "chart_\(chartName).gnuplot"
        let file = try FileDescriptor.open(gnuplotCommandPath,
                                           .writeOnly,
                                           options: [.truncate, .create],
                                           permissions: .ownerReadWrite)
        try file.writeAll(gnuplotCommand.utf8)
        try file.close()
    }
}

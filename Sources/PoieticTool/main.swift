//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 27/06/2023.
//

import PoieticCore

import ArgumentParser

// The Command
// ------------------------------------------------------------------------

struct PoieticTool: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "poietic",
        abstract: "Poietic design utility.",
        subcommands: [
            CreateDB.self,
            Info.self,
            List.self,
            Show.self,
            Edit.self,
//            Print.self,
            Import.self,
//            Export.self,
            Run.self,
            WriteDOT.self,
            MetamodelCommand.self,
            CreateLibrary.self,
        ]
//        defaultSubcommand: List.self
    )
}

struct Options: ParsableArguments {
    @Option(name: [.customLong("design"), .customShort("d")], help: "Path to a design file.")
    var database: String?
}


PoieticTool.main()

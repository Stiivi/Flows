//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 11/07/2022.
//

// Prototyping functions - to be used only during development
//


public func CreatePredatorPreyModel() -> Model {
    let model = Model()
    
    model.add([
        Stock(name: "fish", float: 1000),
        Stock(name: "shark", float: 10),

        Transform(name: "fish_birth_rate", expression: "0.01" ),
        Transform(name: "shark_birth_rate", expression: "0.6" ),
        Transform(name: "shark_efficiency", expression: "0.0003" ),
        Transform(name: "shark_death_rate", expression: "0.15" ),

        Flow(name: "fish_births", expression: "fish * fish_birth_rate"),
        Flow(name: "shark_births", expression: "shark * shark_birth_rate * shark_efficiency * fish"),
        Flow(name: "fish_deaths", expression: "fish * shark_efficiency * shark"),
        Flow(name: "shark_deaths", expression: "shark_death_rate * shark"),
    ])

    model.connect(from: model["fish_birth_rate"]!, to: model["fish_births"]!)
    model.connect(from: model["fish"]!, to: model["fish_births"]!)
    model.connectFlow(from: model["fish_births"]!, to: model["fish"]!)


    model.connect(from: model["shark_birth_rate"]!, to: model["shark_births"]!)
    model.connect(from: model["shark"]!, to: model["shark_births"]!)
    model.connect(from: model["shark_efficiency"]!, to: model["shark_births"]!)
    model.connect(from: model["fish"]!, to: model["shark_births"]!)
    model.connectFlow(from: model["shark_births"]!, to: model["shark"]!)

    model.connect(from: model["fish"]!, to: model["fish_deaths"]!)
    model.connect(from: model["shark_efficiency"]!, to: model["fish_deaths"]!)
    model.connect(from: model["shark"]!, to: model["fish_deaths"]!)
    model.connectFlow(from: model["fish"]!, to: model["fish_deaths"]!)

    model.connect(from: model["shark"]!, to: model["shark_deaths"]!)
    model.connect(from: model["shark_death_rate"]!, to: model["shark_deaths"]!)
    model.connectFlow(from: model["shark"]!, to: model["shark_deaths"]!)

    return model
}

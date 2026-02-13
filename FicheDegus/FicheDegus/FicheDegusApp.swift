//
//  FicheDegusApp.swift
//  FicheDegus
//
//  Created by Florent Flo on 25/01/2026.
//

import SwiftUI

@main
struct FicheDegusApp: App {
    @State private var store = WineStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Accueil", systemImage: "house.fill")
                    }

                AromaWheelView()
                    .tabItem {
                        Label("Roue des Arômes", systemImage: "chart.pie.fill")
                    }
            }
            .environment(store)
        }
    }
}

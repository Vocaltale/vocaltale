//
//  VocaltaleApp.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/23.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        print("opening \(urls)")

        for url in urls {
            let pathExtension = url.pathExtension
            if pathExtension == kDefaultProjectUTType.preferredFilenameExtension {
                LibraryService.instance.openLibrary(from: url)

                continue
            }

            LibraryService.instance.importFiles(from: url)
        }
    }
}

@main
struct VocaltaleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @ObservedObject private var windowRepository = WindowRepository.instance

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(
                    minWidth: 1160,
                    minHeight: 512
                )
        }
        .handlesExternalEvents(matching: [])
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
            }
        }
    }
}

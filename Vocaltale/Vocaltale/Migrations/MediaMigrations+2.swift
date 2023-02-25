//
//  MediaMigrations+2.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/22.
//

import Foundation
import SQLKit

struct MediaMigrations2: MediaMigrations {
    static let version: String = "1.1.0"

    static func up(db: SQLDatabase) throws {
        print("begin: migration")
        do {
            let migrations = try db.select()
                .columns("*")
                .from("migrations")
                .where("version", .equal, SQLBind(version))
                .first()
                .wait()

            if migrations != nil {
                print("\(version) exists")
                return
            }
            print("\(version) not exists")
        } catch {
            print(error)
        }

        try db.create(table: "playlists")
            .column(
                "uuid",
                type: .text,
                [
                    .unique,
                    .notNull
                ]
            )
            .column("name", type: .text, [ .notNull ])
            .column(
                "order",
                type: .int,
                [
                    .notNull
                ]
            )
            .run()
            .wait()

        try db.create(table: "playlist_tracks")
            .column(
                "uuid",
                type: .text,
                [
                    .unique,
                    .notNull
                ]
            )
            .column(
                "playlistID",
                type: .text,
                [
                    .foreignKey(references: SQLColumnConstraintAlgorithm.references("playlists", "uuid")),
                    .notNull
                ]
            )
            .column(
                "trackID",
                type: .text,
                [
                    .foreignKey(references: SQLColumnConstraintAlgorithm.references("tracks", "uuid")),
                    .notNull
                ]
            )
            .column(
                "order",
                type: .int,
                [
                    .notNull
                ]
            )
            .run()
            .wait()

        try db.insert(into: "migrations")
            .columns("version")
            .values(SQLLiteral.string(version))
            .run()
            .wait()
    }

    static func down(db: SQLDatabase) throws {
        try db.drop(table: "playlist_tracks").run().wait()
        try db.drop(table: "playlists").run().wait()
        try db.delete(from: "migrations")
            .where("version", .equal, version)
            .run()
            .wait()
    }
}

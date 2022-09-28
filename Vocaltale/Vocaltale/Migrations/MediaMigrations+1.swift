//
//  MediaMigrations+1.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/27.
//

import Foundation
import SQLKit

struct MediaMigrations1: MediaMigrations {
    static let version: String = "1.0.0"

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

        try db.create(table: "migrations")
            .column(
                "version",
                type: .text,
                [
                    .unique,
                    .notNull
                ]
            )
            .run()
            .wait()

        try db.create(table: "artists")
            .column(
                "uuid",
                type: .text,
                [
                    .unique,
                    .notNull
                ]
            )
            .column("name", type: .text, [])
            .run()
            .wait()

        try db.create(table: "albums")
            .column(
                "uuid",
                type: .text,
                [
                    .unique,
                    .notNull
                ]
            )
            .column("artist", type: .text, [])
            .column(
                "artistID",
                type: .text,
                [
                    .foreignKey(references: SQLColumnConstraintAlgorithm.references("artists", "uuid")),
                    .notNull
                ]
            )
            .column("name", type: .text, [])
            .column(
                "discCount",
                type: .int,
                [
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

        try db.create(table: "tracks")
            .column(
                "uuid",
                type: .text,
                [
                    .unique,
                    .notNull
                ]
            )
            .column(
                "track",
                type: .int,
                [
                    .notNull
                ]
            )
            .column("album", type: .text, [])
            .column(
                "albumID",
                type: .text,
                [
                    .foreignKey(references: SQLColumnConstraintAlgorithm.references("albums", "uuid")),
                    .notNull
                ]
            )
            .column("artist", type: .text, [])
            .column(
                "artistID",
                type: .text,
                [
                    .foreignKey(references: SQLColumnConstraintAlgorithm.references("artists", "uuid")),
                    .notNull
                ]
            )
            .column(
                "filename",
                type: .text,
                [
                    .notNull
                ]
            )
            .column("name", type: .text, [])
            .column(
                "duration",
                type: .int,
                [
                    .notNull
                ]
            )
            .column(
                "disc",
                type: .int,
                [
                    .notNull
                ]
            )
            .column(
                "hash",
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
        try db.drop(table: "tracks").run().wait()
        try db.drop(table: "albums").run().wait()
        try db.drop(table: "artists").run().wait()
        try db.drop(table: "migrations").run().wait()
    }
}

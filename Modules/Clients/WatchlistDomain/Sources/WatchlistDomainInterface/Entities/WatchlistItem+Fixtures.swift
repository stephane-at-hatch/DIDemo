//
//  WatchlistItem+Fixtures.swift
//  WatchlistDomainInterface
//
//  Created by Stephane Magne
//

import Foundation

extension WatchlistItem {

    /// A fixture item for previews and testing.
    public static var fixture: WatchlistItem {
        WatchlistItem(
            id: 550,
            title: "Fight Club",
            overview: "A depressed man suffering from insomnia meets a strange soap salesman.",
            posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
            releaseYear: "1999",
            voteAverage: 8.4,
            dateAdded: Date().addingTimeInterval(-86400)
        )
    }

    /// Multiple fixture items for previews and testing.
    public static var fixtures: [WatchlistItem] {
        [
            WatchlistItem(
                id: 550,
                title: "Fight Club",
                overview: "A depressed man suffering from insomnia meets a strange soap salesman.",
                posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
                releaseYear: "1999",
                voteAverage: 8.4,
                dateAdded: Date().addingTimeInterval(-86400)
            ),
            WatchlistItem(
                id: 27205,
                title: "Inception",
                overview: "A thief who steals corporate secrets through dream-sharing technology.",
                posterPath: "/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg",
                releaseYear: "2010",
                voteAverage: 8.4,
                dateAdded: Date().addingTimeInterval(-172800)
            ),
            WatchlistItem(
                id: 157336,
                title: "Interstellar",
                overview: "A team of explorers travel through a wormhole in space.",
                posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
                releaseYear: "2014",
                voteAverage: 8.6,
                dateAdded: Date().addingTimeInterval(-259200)
            )
        ]
    }
}

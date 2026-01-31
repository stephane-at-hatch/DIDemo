//
//  MovieDTO.swift
//  TMDBClientInterface
//
//  Created by Stephane Magne
//

import Foundation

/// A movie object as returned from TMDB list endpoints (now playing, popular, search, etc.)
public struct MovieListItemDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let title: String
    public let originalTitle: String
    public let overview: String
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: String?
    public let voteAverage: Double
    public let voteCount: Int
    public let popularity: Double
    public let adult: Bool
    public let video: Bool
    public let genreIds: [Int]
    public let originalLanguage: String

    public init(
        id: Int,
        title: String,
        originalTitle: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        releaseDate: String?,
        voteAverage: Double,
        voteCount: Int,
        popularity: Double,
        adult: Bool,
        video: Bool,
        genreIds: [Int],
        originalLanguage: String
    ) {
        self.id = id
        self.title = title
        self.originalTitle = originalTitle
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.popularity = popularity
        self.adult = adult
        self.video = video
        self.genreIds = genreIds
        self.originalLanguage = originalLanguage
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case originalTitle = "original_title"
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case popularity
        case adult
        case video
        case genreIds = "genre_ids"
        case originalLanguage = "original_language"
    }
}

/// Detailed movie information as returned from the movie details endpoint.
public struct MovieDetailDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let title: String
    public let originalTitle: String
    public let overview: String
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: String?
    public let voteAverage: Double
    public let voteCount: Int
    public let popularity: Double
    public let adult: Bool
    public let video: Bool
    public let originalLanguage: String
    public let budget: Int
    public let revenue: Int
    public let runtime: Int?
    public let status: String
    public let tagline: String?
    public let homepage: String?
    public let imdbId: String?
    public let genres: [GenreDTO]
    public let productionCompanies: [ProductionCompanyDTO]
    public let productionCountries: [ProductionCountryDTO]
    public let spokenLanguages: [SpokenLanguageDTO]

    public init(
        id: Int,
        title: String,
        originalTitle: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        releaseDate: String?,
        voteAverage: Double,
        voteCount: Int,
        popularity: Double,
        adult: Bool,
        video: Bool,
        originalLanguage: String,
        budget: Int,
        revenue: Int,
        runtime: Int?,
        status: String,
        tagline: String?,
        homepage: String?,
        imdbId: String?,
        genres: [GenreDTO],
        productionCompanies: [ProductionCompanyDTO],
        productionCountries: [ProductionCountryDTO],
        spokenLanguages: [SpokenLanguageDTO]
    ) {
        self.id = id
        self.title = title
        self.originalTitle = originalTitle
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.popularity = popularity
        self.adult = adult
        self.video = video
        self.originalLanguage = originalLanguage
        self.budget = budget
        self.revenue = revenue
        self.runtime = runtime
        self.status = status
        self.tagline = tagline
        self.homepage = homepage
        self.imdbId = imdbId
        self.genres = genres
        self.productionCompanies = productionCompanies
        self.productionCountries = productionCountries
        self.spokenLanguages = spokenLanguages
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case originalTitle = "original_title"
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case popularity
        case adult
        case video
        case originalLanguage = "original_language"
        case budget
        case revenue
        case runtime
        case status
        case tagline
        case homepage
        case imdbId = "imdb_id"
        case genres
        case productionCompanies = "production_companies"
        case productionCountries = "production_countries"
        case spokenLanguages = "spoken_languages"
    }
}

public struct GenreDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public struct ProductionCompanyDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let name: String
    public let logoPath: String?
    public let originCountry: String

    public init(id: Int, name: String, logoPath: String?, originCountry: String) {
        self.id = id
        self.name = name
        self.logoPath = logoPath
        self.originCountry = originCountry
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case logoPath = "logo_path"
        case originCountry = "origin_country"
    }
}

public struct ProductionCountryDTO: Codable, Sendable, Equatable {
    public let iso3166_1: String
    public let name: String

    public init(iso3166_1: String, name: String) {
        self.iso3166_1 = iso3166_1
        self.name = name
    }

    private enum CodingKeys: String, CodingKey {
        case iso3166_1 = "iso_3166_1"
        case name
    }
}

public struct SpokenLanguageDTO: Codable, Sendable, Equatable {
    public let iso639_1: String
    public let name: String
    public let englishName: String?

    public init(iso639_1: String, name: String, englishName: String?) {
        self.iso639_1 = iso639_1
        self.name = name
        self.englishName = englishName
    }

    private enum CodingKeys: String, CodingKey {
        case iso639_1 = "iso_639_1"
        case name
        case englishName = "english_name"
    }
}

//
//  Pokemon.swift
//  GoGoPokemonLook
//
//  Created by 黃柏叡 on 2024/6/25.
//

import Foundation
import Combine

struct PokemonList: Decodable {
	let count: Int
	let next: String
	let previous: String?
	let results: [Pokemon]
}

class Pokemon: ObservableObject, Decodable {

	let name: String
	let url: String
	var id: String {
		guard let idSubString = url.split(separator: "/").last else { return "" }
		return String(idSubString)
	}
	
	@Published
	var detail: PokemonDetail?
	
	var species: SpeciesDetail?
	
	init(name: String, url: String) {
		self.name = name
		self.url = url
	}
	
	enum CodingKeys: String, CodingKey {
		case name
		case url
	}
}

extension Pokemon: Hashable {
	
	nonisolated func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(url)
	}
	
	static func == (lhs: Pokemon, rhs: Pokemon) -> Bool {
		lhs.name == rhs.name && lhs.url == rhs.url
	}
}

extension Pokemon {
	
	convenience init?(species: SpeciesElement) {
		guard let id = species.url.split(separator: "/").last else { return nil }
		self.init(name: species.name, url: "https://pokeapi.co/api/v2/pokemon/\(id)")
	}
}


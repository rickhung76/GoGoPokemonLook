//
//  PokemonDetailModel.swift
//  GoGoPokemonLook
//
//  Created by 黃柏叡 on 2024/6/26.
//

import Foundation
import Combine
import FiredTofu

typealias PokemonDetailModelDataProvider = PokemonDetailDataProvider 
& PokemonSpeciesDataProvider
& PokemonEvolutionChainDataProvider

protocol PokemonSpeciesDataProvider {
	func fetchSpecies(_ url: String) -> AnyPublisher<SpeciesDetail, NSError>
}

protocol PokemonEvolutionChainDataProvider {
	func fetchEvolutionChain(_ url: String) -> AnyPublisher<EvolutionChain, NSError>
}

class PokemonDetailModel: ObservableObject {
	
	struct EvolutionChainViewModel: Hashable {
		let chain: ChainElement
		let isClickable: Bool
	}
	
	let pokemon: PokemonViewModel
	
	@Published
	var flavor: String = ""
	
	@Published
	var evolves: [EvolutionChainViewModel] = []
		
	private var cancelable = Set<AnyCancellable>()
	
	private let dataProvider: PokemonDetailModelDataProvider
	
	init(
		pokemon: PokemonViewModel,
		dataProvider: PokemonDetailModelDataProvider = HttpClient.default
	) {
		self.pokemon = pokemon
		self.dataProvider = dataProvider
		
		if self.pokemon.detail == nil {
			fetchPokemonDetail()
		}
	}
	
	func fetchPokemonDetail() {
		dataProvider
			.fetchDetail(pokemon.url)
			.receive(on: DispatchQueue.main)
			.sink { [weak self] completion in
				guard let self else { return }
				switch completion {
				case .finished:
					self.fetchPokemonSpecies()
				case .failure(let error):
					print(error.localizedDescription)
				}
			} receiveValue: { [weak self] detail in
				self?.pokemon.detail = detail
			}.store(in: &cancelable)
	}
	
	func fetchPokemonSpecies() {
		guard let detail = pokemon.detail else { return }
		dataProvider
			.fetchSpecies(detail.species.url)
			.receive(on: DispatchQueue.main)
			.sink { _ in
				
			} receiveValue: { [weak self] species in
				guard let self else { return }
				print(species.evolutionChain)
				self.pokemon.species = species
				self.flavor = species.getFlavor()
				self.fetchEvolutionChain()
			}.store(in: &cancelable)
	}
	
	func fetchEvolutionChain() {
		guard let url = pokemon.species?.evolutionChain.url else { return }
		dataProvider
			.fetchEvolutionChain(url)
			.receive(on: DispatchQueue.main)
			.sink { _ in
				
			} receiveValue: { [weak self] chain in
				guard let self else { return }
				self.evolves = chain
					.chain
					.allEvolvesRecursively
					.map {
						EvolutionChainViewModel(
							chain: $0,
							isClickable: $0.species.name != self.pokemon.name
						)
					}
			}.store(in: &cancelable)
	}
}
